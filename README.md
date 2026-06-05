# Lepro Control for macOS

A native macOS control panel for managing Lepro WiFi LED strips directly from a desktop application.

This project provides a dashboard to authenticate with Lepro Cloud, list your compatible Lepro devices, and control basic light functions such as power state and brightness.

## Overview

The application includes:

- Lepro Cloud authentication
- Device discovery
- LED strip power, brightness and colour control

## Inspiration

This project is technically inspired by the open-source [`lepro_led`](https://github.com/Sanji78/lepro_led) integration for Home Assistant.

The `lepro_led` repository was used as a reference to understand how Lepro Cloud communication works. This project is an adaptation which does not depend on Home Assistant and HACS.

## Security

Sensitive data is not stored in plain text.

The app uses macOS Keychain to store session-related information such as tokens or credentials required for authenticated requests.

Do not hardcode real credentials or tokens in the source code.

## Requirements

- macOS
- Xcode
- Swift
- SwiftUI
- A Lepro account
- Compatible Lepro WiFi LED strip
- Internet connection for Lepro Cloud communication

## Running the Project

1. Clone the repository:

```bash
git clone <your-repository-url>
cd <your-project-folder>
```

2. Open the project in Xcode:

```bash
open LeproControl.xcodeproj
```

3. Build and run the app.

4. Log in using your Lepro account.

5. Select a device from the sidebar.

6. Control power and brightness from the dashboard.

## Limitations

This app currently depends on Lepro Cloud. It does not control the LED strips directly over the local network.

That means:

- Internet access is required.
- Lepro Cloud must be available.
- Changes to Lepro's private API may break functionality.
- Not all Lepro devices may be supported.
- Advanced features such as scenes, colors, music sync, or effects may require additional API research.

## Not Affiliated With Lepro

This is an independent project and is not affiliated with, endorsed by, or officially supported by Lepro.

Lepro is a trademark of its respective owner.

## Credits

This project is inspired by the technical work done in the open-source Home Assistant custom integration:

- [`Sanji78/lepro_led`](https://github.com/Sanji78/lepro_led)

## License

```text
MIT License
```
