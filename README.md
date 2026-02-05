# Homebase Manager

A Flutter-based dashboard for managing remote hosts via SSH. Monitor health, execute custom actions, and manage device authorization.

## Features

- **Health Monitoring**: View uptime and failed systemd services.
- **SSH Terminal**: Integrated terminal for direct access.
- **Custom Actions**: Define shell commands in your config to run with one click (e.g., restarting services, updates).
- **Standard Actions**: Quick access to Reboot and Power Off.
- **Device Authorization**: Easily push your device's SSH public key to remote hosts to enable passwordless login.
- **Flexible Config**: Load configuration from a local file or a remote URL (supports SOPS/Age encryption).

## Configuration

The application uses a YAML configuration file. See [config.example.yaml](config.example.yaml) for a template.

### Example Schema

```yaml
hosts:
  - name: "My Server"
    address: "192.168.1.10"
    username: "user"
    root_access: true
    actions:
      - name: "Restart Web Service"
        command: "sudo systemctl restart nginx"
    authorized_keys:
      - "ssh-ed25519 ..."
```

## Getting Started

1. **Install**: Download the latest build for your platform from the [Releases](https://github.com/Sammyalhashe/homebase-manager/releases) section.
2. **Setup Config**: Create a YAML file following the example.
3. **Configure App**: Go to **Settings** in the app and provide the path or URL to your config.

## Development

This project uses Flutter and Nix.

```bash
nix develop
flutter run
```