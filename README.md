errlog-ios
==========

Errlog client for errlog.co monitoring service.

This is a early beta version, it is functional but it might need some effort to
incorporate.

Installing
==========

Drag `src` folder into your XCode project, check 'sopy files...' and 'create groups...'.
Add initialization to your didFinishLaunch like:

	    [Errlog useAccountId:@"<use-your-id>" secret:@"<your-secret>" application:@"YourApplicationName"];

We encourage using git submodule while beta test to easily update fast changing client code.

Visit http://errorlog.co to obtain your own credentials to start.

Questions
=========

First, visit http://errorlog.co/help - then leave the issue tagged as question.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Good luck!