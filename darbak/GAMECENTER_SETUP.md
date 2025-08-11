# Game Center Setup Guide

## Current Issues
Your app is experiencing Game Center authentication failures because Game Center hasn't been properly configured in App Store Connect. The error message indicates:

```
"The requested operation could not be completed because this application is not recognized by Game Center."
```

## Step-by-Step Fix

### 1. Enable Game Center in App Store Connect

1. **Log into App Store Connect** (https://appstoreconnect.apple.com)
2. **Navigate to your app**: My Apps → Select your app
3. **Go to Game Center tab**: In the left sidebar, click "Game Center"
4. **Enable Game Center**: Click "Enable Game Center" if it's not already enabled
5. **Configure Leaderboards**: Create the following leaderboards:
   - `daily_steps_leaderboard` - Daily step count
   - `weekly_steps_leaderboard` - Weekly step count  
   - `total_steps_leaderboard` - Total step count
   - `streak_leaderboard` - Streak days

### 2. Verify Bundle ID
Ensure your app's bundle identifier matches exactly: `com.impact.darbak`

### 3. Check Entitlements
The Game Center entitlement is already present in `darbak.entitlements`:
```xml
<key>com.apple.developer.game-center</key>
<true/>
```

### 4. Verify Info.plist
The required keys are now present:
- `NSGKFriendListUsageDescription` - Added for friends access
- `UIRequiredDeviceCapabilities` - Includes `gamekit`

### 5. Test on Device
- **Important**: Game Center features only work on physical devices, not in the simulator
- Make sure you're signed into Game Center on your device
- Test the app on a device with a valid Apple ID

## Debug Features Added

### Game Center Debug View
I've added a debug interface accessible from the Profile tab:
- Shows authentication status
- Displays player information when connected
- Provides retry and manual login options
- Includes troubleshooting guide

### Enhanced Error Handling
- Retry logic with exponential backoff
- Better error messages and logging
- Prevents excessive API calls when not authenticated

## Common Issues and Solutions

### Issue: "App not recognized by Game Center"
**Solution**: Enable Game Center in App Store Connect (Step 1 above)

### Issue: Authentication fails repeatedly
**Solution**: 
1. Check if signed into Game Center on device
2. Try signing out and back into Game Center
3. Restart the device
4. Use the debug view to retry authentication

### Issue: Leaderboards not loading
**Solution**: 
1. Ensure leaderboards are created in App Store Connect
2. Wait 24-48 hours for changes to propagate
3. Test on a physical device, not simulator

### Issue: Friends not loading
**Solution**: 
1. Make sure you have Game Center friends
2. Check that `NSGKFriendListUsageDescription` is in Info.plist
3. Grant permission when prompted

## Testing Checklist

- [ ] Game Center enabled in App Store Connect
- [ ] Leaderboards created with correct IDs
- [ ] Testing on physical device (not simulator)
- [ ] Signed into Game Center on device
- [ ] App has Game Center entitlement
- [ ] Info.plist has required keys
- [ ] Bundle ID matches exactly

## Debug Commands

Use the debug view in the app or call these methods in code:

```swift
// Debug Game Center status
GameCenterManager.shared.debugGameCenterStatus()

// Retry authentication
GameCenterManager.shared.retryAuthentication()

// Manual login
GameCenterManager.shared.presentGameCenterLogin()
```

## Timeline
After enabling Game Center in App Store Connect, it may take 24-48 hours for all features to become fully available. During this time, you may see intermittent authentication failures.

## Support
If issues persist after following these steps:
1. Check Apple's Game Center documentation
2. Verify your Apple Developer account has Game Center enabled
3. Contact Apple Developer Support if needed
