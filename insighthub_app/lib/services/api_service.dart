import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Central API service for communicating with the InsightHub FastAPI backend.
/// 
/// Features:
/// - Automatic retry logic for transient failures
/// - Platform-specific URL configuration
/// - Comprehensive error handling
class ApiService {
  /// Maximum number of retry attempts for failed requests
  static const int maxRetries = 3;

  /// Delay between retries (milliseconds)
  static const Duration retryDelay = Duration(milliseconds: 500);

  /// Get the base URL, with optional override for testing
  static String get _baseUrl => ApiConfig.baseUrl;

  /// ─── GET /insights ────────────────────────────────────────────────────
  /// Fetches the full analytics payload from the backend with retry logic.
  static Future<Map<String, dynamic>> getInsights({int retryCount = 0}) async {
    try {
      debugLog('Fetching insights from $_baseUrl/insights (attempt ${retryCount + 1})');
      
      final response = await http
          .get(Uri.parse('$_baseUrl/insights'))
          .timeout(Duration(seconds: ApiConfig.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugLog('Successfully fetched insights');
        return data;
      } else if (response.statusCode == 503 || response.statusCode == 500 || response.statusCode == 502) {
        // Retry on server errors
        if (retryCount < maxRetries) {
          debugLog('Server error ${response.statusCode}, retrying...');
          await Future.delayed(retryDelay);
          return getInsights(retryCount: retryCount + 1);
        }
        throw HttpException(
          'Server error ${response.statusCode}: ${response.body}',
        );
      } else {
        throw HttpException(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      // Retry on timeout
      if (retryCount < maxRetries) {
        debugLog('Request timeout, retrying... (attempt ${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return getInsights(retryCount: retryCount + 1);
      }
      throw Exception('Request timeout: Failed to fetch insights after $maxRetries retries. '
          'Make sure the backend server is running at $_baseUrl');
    } catch (e) {
      if (retryCount < maxRetries && _isRetryable(e)) {
        debugLog('Error occurred, retrying... $e');
        await Future.delayed(retryDelay);
        return getInsights(retryCount: retryCount + 1);
      }
      throw Exception('Failed to fetch insights: $e\n'
          'Backend URL: $_baseUrl\n'
          'Make sure the InsightHub API server is running.');
    }
  }

  /// ─── POST /upload ─────────────────────────────────────────────────────
  /// Uploads a CSV file to the backend for processing with retry logic.
  static Future<Map<String, dynamic>> uploadFile(File file, {int retryCount = 0}) async {
    try {
      debugLog('Uploading file ${file.path} to $_baseUrl/upload (attempt ${retryCount + 1})');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
        ),
      );

      final streamedResponse =
          await request.send().timeout(Duration(seconds: ApiConfig.uploadTimeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugLog('File uploaded successfully');
        return data;
      } else if (response.statusCode == 503 || response.statusCode == 500 || response.statusCode == 502) {
        // Retry on server errors
        if (retryCount < maxRetries) {
          debugLog('Server error ${response.statusCode}, retrying...');
          await Future.delayed(retryDelay);
          return uploadFile(file, retryCount: retryCount + 1);
        }
        final body = json.decode(response.body);
        throw HttpException(
          body['detail'] ?? 'Server error ${response.statusCode}',
        );
      } else {
        final body = json.decode(response.body);
        throw HttpException(
          body['detail'] ?? 'Upload failed with status ${response.statusCode}',
        );
      }
    } on TimeoutException {
      // Retry on timeout
      if (retryCount < maxRetries) {
        debugLog('Request timeout, retrying... (attempt ${retryCount + 1}/$maxRetries)');
        await Future.delayed(retryDelay);
        return uploadFile(file, retryCount: retryCount + 1);
      }
      throw Exception('Upload timeout: Failed to upload after $maxRetries retries. '
          'Make sure the backend server is running at $_baseUrl');
    } catch (e) {
      if (retryCount < maxRetries && _isRetryable(e)) {
        debugLog('Error occurred, retrying... $e');
        await Future.delayed(retryDelay);
        return uploadFile(file, retryCount: retryCount + 1);
      }
      throw Exception('Failed to upload file: $e\n'
          'Backend URL: $_baseUrl\n'
          'Make sure the InsightHub API server is running.');
    }
  }

  /// Check if an exception is retryable
  static bool _isRetryable(dynamic exception) {
    if (exception is SocketException) {
      // Retry on connection errors
      return true;
    }
    if (exception is HttpException) {
      final message = exception.message.toLowerCase();
      // Retry on specific connection issues
      return message.contains('connection') ||
             message.contains('refused') ||
             message.contains('not found') ||
             message.contains('failed');
    }
    return false;
  }
}

