import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

class WidgetService {
  static const String _appGroupId = 'com.bharathi.petals';
  static const List<String> _androidWidgetNames = [
    'SmallWidget',
    'MediumWidget',
    'LargeWidget',
    'CompactWidget',
  ];

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('WidgetService initialize error: $e');
    }
  }

  /// Cache image to app documents directory (NOT temp — survives app restarts)
  static Future<String?> _cacheImageLocally(String imageUrl) async {
    try {
      // Use documents dir so it's NOT cleared by the OS
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/widget_current_image.jpg');

      if (imageUrl.startsWith('data:image')) {
        final base64Clean = imageUrl.split(',').last;
        final bytes = base64Decode(base64Clean);
        await file.writeAsBytes(bytes);
        debugPrint('WidgetService: cached base64 image to ${file.path}');
        return file.path;
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(imageUrl));
          final response = await request.close();
          if (response.statusCode == HttpStatus.ok) {
            final bytes = await response.fold<List<int>>(
              <int>[],
              (previous, element) => previous..addAll(element),
            );
            await file.writeAsBytes(bytes);
            debugPrint('WidgetService: downloaded HTTP image to ${file.path}');
            return file.path;
          }
        } finally {
          client.close();
        }
      } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
        final cleanPath = imageUrl.replaceFirst('file://', '');
        final srcFile = File(cleanPath);
        if (await srcFile.exists()) {
          await srcFile.copy(file.path);
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('WidgetService: Error caching widget image locally: $e');
    }
    return null;
  }

  static Future<void> updateWidget({
    required String imageUrl,
    required String caption,
    required String posterName,
    String? myName,
    String? partnerName,
    DateTime? time,
  }) async {
    if (kIsWeb) return;
    try {
      // Save image URL
      if (imageUrl.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_image_url', imageUrl);
      } else {
        // Don't pass null to typed generic — use empty string to clear
        await HomeWidget.saveWidgetData<String>('widget_image_url', '');
      }

      // Pre-cache image to persistent local file for instant native widget access
      if (imageUrl.isNotEmpty) {
        final localPath = await _cacheImageLocally(imageUrl);
        if (localPath != null) {
          await HomeWidget.saveWidgetData<String>('widget_image_path', localPath);
          debugPrint('WidgetService: saved widget_image_path=$localPath');
        }
      } else {
        await HomeWidget.saveWidgetData<String>('widget_image_path', '');
      }

      await HomeWidget.saveWidgetData<String>('widget_caption', caption);
      await HomeWidget.saveWidgetData<String>('widget_poster_name', posterName);

      if (myName != null && myName.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_my_name', myName);
      }
      if (partnerName != null && partnerName.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('widget_partner_name', partnerName);
      }

      await HomeWidget.saveWidgetData<String>(
        'widget_time',
        (time ?? DateTime.now()).toUtc().toIso8601String(),
      );

      debugPrint('WidgetService: saved all widget data, triggering update...');

      // Trigger widget update for all widget types
      for (final name in _androidWidgetNames) {
        try {
          await HomeWidget.updateWidget(
            name: name,
            androidName: name,
            iOSName: 'PetalsWidget',
          );
          debugPrint('WidgetService: triggered update for $name');
        } catch (e) {
          debugPrint('WidgetService: Error updating widget $name: $e');
        }
      }
    } catch (e) {
      debugPrint('WidgetService: Error updating widget data: $e');
    }
  }

  static Future<void> clearWidget() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('widget_image_url', '');
      await HomeWidget.saveWidgetData<String>('widget_image_path', '');
      await HomeWidget.saveWidgetData<String>('widget_caption', '');
      await HomeWidget.saveWidgetData<String>('widget_poster_name', '');
      for (final name in _androidWidgetNames) {
        try {
          await HomeWidget.updateWidget(
            name: name,
            androidName: name,
            iOSName: 'PetalsWidget',
          );
        } catch (e) {
          debugPrint('WidgetService: Error clearing widget $name: $e');
        }
      }
    } catch (e) {
      debugPrint('WidgetService: Error clearing widget data: $e');
    }
  }
}
