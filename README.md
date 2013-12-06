errlog-ios
==========

Errlog client for errlog.co monitoring service.

This is a early beta version, it is functional but it might need some effort to
incorporate.

Installing
==========

Drag `src` folder into your XCode project, check 'sopy files...' and 'create groups...'.
Add initialization to your didFinishLaunch like:

	        [Errlog useToken:@"your token"
	        	 application:@"AppName"];

	        [Errlog trace:@"my trace" data: nil]; // Se Errlog.h for API

	        // Report an event for behavoidr logging:
	        [Errlog event:@"Logged in" data: nil];

Errlog.h also redefines NSLog to capture your logs, so include it early to see logs in
your reports.

Errlog installs a handler for uncaught exceptions and does its best to report the fatals
during the next application start (it is not possible to do it synchronously at this moment)

We encourage using git submodule while beta test to easily update fast changing client code.

Visit http://errorlog.co to obtain the token.

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