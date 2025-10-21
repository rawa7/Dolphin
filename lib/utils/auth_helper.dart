import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/login_screen.dart';
import '../generated/app_localizations.dart';

class AuthHelper {
  /// Check if user is logged in and show dialog if not
  /// Returns true if user is logged in, false otherwise
  static Future<bool> requireAuth(BuildContext context) async {
    final isLoggedIn = await StorageService.isLoggedIn();
    
    if (!isLoggedIn && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.pleaseLogin,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.loginRequired),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C1B5E),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.loginNow),
            ),
          ],
        ),
      );
      
      if (result == true && context.mounted) {
        // Navigate to login screen
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        
        // Check if user logged in
        return await StorageService.isLoggedIn();
      }
      
      return false;
    }
    
    return isLoggedIn;
  }
  
  /// Quick check without dialog
  static Future<bool> isAuthenticated() async {
    return await StorageService.isLoggedIn();
  }
}

