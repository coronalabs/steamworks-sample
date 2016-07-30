# Corona SDK Steamworks Plugin sample app

This is an example of how to incorporate Steamworks leaderboards and achievements into your Corona SDK built app.

## Gotchas

* For Overlays, you need to enable them in your Steamworks client settings.
* For the Windows simulator, you should run a borderless Android device window such as "Amazon Fire TV".
* For the Windows simulator, iOS simulators will not process keyboard input.
* For the macOS simulator, you should launch Corona SDK from the Steamworks client to get overlays to work.
* macOS build require special signing instructions. See below.

## Documentation

Please see our [Steamworks plugin documentation](https://docs.coronalabs.com/plugin/steamworks/index.html)

## Signing Steamworks apps for macOS

The process of signing your app for Steamworks is different than for the Mac App Store. You need to sign your app with an Apple "Developer ID Application" certificate.  This certificate is intended for apps that will be distributed outside of the Mac App Store, such as Steam... or as a download from your own website.  Info about this certificate can be found at [Apple's website here...](https://developer.apple.com/developer-id/)
 
Once you've acquired a "Developer ID Application" certificate from Apple's developer portal and installed it on your machine, you can then build and sign your app as follows:

* In the Corona Simulator's "Build for OS X" window, select "None" from the "Provisioning Profile" drop-down box.
* Click the "Build" button.  (Note that this app will not be signed.)
* Open the "Terminal" application.
* Run the following command line to sign the app yourself.

    
    codesign --deep -f -s "Developer ID Application: <YourCompanyName>" <PathToYour.app>
    

Note that you need to fill in the above <YourCompanyName> and <PathtoYour.app> with the appropriate text.  And the "Developer ID Application: <YourCompanyName>" will be the full name of your certificate you see listed in Apple's Keychain application once the certificate is installed.  Once signed, your app will no longer be blocked by OS X's "Gatekeeper" feature.
