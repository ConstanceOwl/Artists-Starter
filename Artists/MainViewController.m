//
//  MainViewController.m
//  Artists
//
//  Created by Matthijs Hollemans.
//  Copyright 2011 Razeware LLC. All rights reserved.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "MainViewController.h"
#import "SVProgressHUD.h"
#import "AFHTTPRequestOperation.h"
#import "SoundEffect.h"

@interface MainViewController ()
{
    NSOperationQueue *queue;
	NSMutableString *currentStringValue;
    NSMutableArray *searchResults;
    SoundEffect *soundEffect;
}

@end

@implementation MainViewController

@synthesize tableView;
@synthesize searchBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		queue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.searchBar becomeFirstResponder];
}

- (void)viewDidUnload
{
	[super viewDidUnload];

    NSLog(@"tableView %@", self.tableView);
    NSLog(@"searchBar %@", self.searchBar);

	soundEffect = nil;
}

- (void)dealloc
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (SoundEffect *)soundEffect
{
	if (soundEffect == nil)  // lazy loading
	{
		soundEffect = [[SoundEffect alloc] initWithSoundNamed:@"Sound.caf"];
	}
	return soundEffect;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (searchResults == nil)
		return 0;
	else if ([searchResults count] == 0)
		return 1;
	else
		return [searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

	if ([searchResults count] == 0)
		cell.textLabel.text = @"(Nothing found)";
	else
		cell.textLabel.text = [searchResults objectAtIndex:indexPath.row];

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[theTableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *artistName = [searchResults objectAtIndex:indexPath.row];;

    DetailViewController *controller = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    controller.delegate = self;
    controller.artistName = artistName;
    [self presentViewController:controller animated:YES completion:nil];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([searchResults count] == 0)
    {
        return nil;
    }
    else
    {
        return indexPath;
    }
}

#pragma mark - UISearchBarDelegate

- (NSString *)userAgent
{
	return [NSString stringWithFormat:@"%@/%@ (%@, %@ %@, %@, Scale/%f)",
		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey],
		[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey],
		@"unknown",
		[[UIDevice currentDevice] systemName],
		[[UIDevice currentDevice] systemVersion],
		[[UIDevice currentDevice] model],
		([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0)];
}

- (NSString *)escape:(NSString *)text
{
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
		NULL,
		(__bridge CFStringRef)text,
		NULL,
		(CFStringRef)@"!*'();:@&=+$,/?%#[]",
		CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
	[SVProgressHUD showInView:self.view status:nil networkIndicator:YES posY:-1 maskType:SVProgressHUDMaskTypeGradient];

	NSString *urlString = [NSString stringWithFormat:@"http://musicbrainz.org/ws/2/artist?query=artist:%@&limit=20", [self escape:searchBar.text]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

	NSDictionary *headers = [NSDictionary dictionaryWithObject:[self userAgent] forKey:@"User-Agent"];
	[request setAllHTTPHeaderFields:headers];

	AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error)
	{
		if (response.statusCode == 200 && data != nil)
		{
			searchResults = [NSMutableArray arrayWithCapacity:10];

			NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
			[parser setDelegate:self];
			[parser parse];

			[searchResults sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[[self soundEffect] play];
				[self.tableView reloadData];
				[SVProgressHUD dismiss];
			});
		}
		else  // something went wrong
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[SVProgressHUD dismissWithError:@"Error"];
			});
		}
	}];

	[queue addOperation:operation];

	[theSearchBar resignFirstResponder];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"sort-name"])
	{
		currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (currentStringValue != nil)
	{
		[currentStringValue appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"sort-name"])
	{
		[searchResults addObject:currentStringValue];
		currentStringValue = nil;
	}
}

#pragma mark - DetailViewControllerDelegate

- (void)detailViewController:(DetailViewController *)controller didPickButtonWithIndex:(NSInteger)buttonIndex
{
    NSLog(@"Picked button %d", buttonIndex);
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
