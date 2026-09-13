import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Stands in for the real platform channel `url_launcher` talks to, so
/// tests can assert what URL an app tried to open without actually
/// launching a browser. Install with `UrlLauncherPlatform.instance = fake`
/// in setUp, and restore the original in tearDown.
///
/// `MockPlatformInterfaceMixin` is required here: platform interfaces
/// refuse to accept a plain `implements` fake as their `.instance` unless
/// it's present, to stop real plugins from being silently swapped out.
class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool canLaunchResult = true;
  bool launchResult = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchResult;
  }
}
