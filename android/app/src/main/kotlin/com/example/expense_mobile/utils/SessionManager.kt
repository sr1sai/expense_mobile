package com.example.expense_mobile.utils

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

/**
 * SessionManager for storing and retrieving user session data
 * Mirrors the UserSession class from Dart side
 * IMPORTANT: Uses same SharedPreferences as Flutter's shared_preferences plugin
 */
object SessionManager {
    private const val TAG = "SessionManager"
    // Match Flutter's shared_preferences plugin storage name
    private const val PREFS_NAME = "FlutterSharedPreferences"
    // Keys with "flutter." prefix to match shared_preferences plugin format
    private const val KEY_USER_ID = "flutter.user_id"
    private const val KEY_USER_NAME = "flutter.user_name"
    private const val KEY_USER_EMAIL = "flutter.user_email"
    private const val KEY_USER_PHONE = "flutter.user_phone"
    private const val KEY_IS_LOGGED_IN = "flutter.is_logged_in"
    private const val KEY_DEVICE_ID = "flutter.device_id"
    
    /**
     * Get SharedPreferences instance
     */
    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * Save user session data after successful login
     */
    fun saveUser(context: Context, userId: String, name: String, email: String, phoneNumber: String) {
        Log.d(TAG, "==================== SAVING USER SESSION ====================")
        Log.d(TAG, "User ID: $userId")
        Log.d(TAG, "Name: $name")
        Log.d(TAG, "Email: $email")
        Log.d(TAG, "Phone: $phoneNumber")
        
        getPrefs(context).edit().apply {
            putString(KEY_USER_ID, userId)
            putString(KEY_USER_NAME, name)
            putString(KEY_USER_EMAIL, email)
            putString(KEY_USER_PHONE, phoneNumber)
            putBoolean(KEY_IS_LOGGED_IN, true)
            apply()
        }
        
        Log.d(TAG, "✓ User session saved successfully")
    }
    
    /**
     * Get current user ID (for SMS service to send to backend)
     * Returns null if user is not logged in
     */
    fun getUserId(context: Context): String? {
        val prefs = getPrefs(context)
        val isLoggedIn = prefs.getBoolean(KEY_IS_LOGGED_IN, false)
        
        if (!isLoggedIn) {
            Log.w(TAG, "User not logged in - using default device ID")
            // Return a device-specific UUID for non-logged-in users
            return getOrCreateDeviceId(context)
        }
        
        val userId = prefs.getString(KEY_USER_ID, null)
        Log.d(TAG, "Retrieved user ID: $userId")
        return userId
    }
    
    /**
     * Generate or retrieve a unique device ID for non-logged-in users
     */
    private fun getOrCreateDeviceId(context: Context): String {
        val prefs = getPrefs(context)
        val existingId = prefs.getString(KEY_DEVICE_ID, null)
        
        if (existingId != null) {
            Log.d(TAG, "Using existing device ID: $existingId")
            return existingId
        }
        
        // Generate a new device-specific UUID
        val deviceId = java.util.UUID.randomUUID().toString()
        prefs.edit().putString(KEY_DEVICE_ID, deviceId).apply()
        Log.d(TAG, "Generated new device ID: $deviceId")
        return deviceId
    }
    
    /**
     * Get user name
     */
    fun getUserName(context: Context): String? {
        return getPrefs(context).getString(KEY_USER_NAME, null)
    }
    
    /**
     * Get user email
     */
    fun getUserEmail(context: Context): String? {
        return getPrefs(context).getString(KEY_USER_EMAIL, null)
    }
    
    /**
     * Get user phone number
     */
    fun getUserPhone(context: Context): String? {
        return getPrefs(context).getString(KEY_USER_PHONE, null)
    }
    
    /**
     * Check if user is logged in
     */
    fun isLoggedIn(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_IS_LOGGED_IN, false)
    }
    
    /**
     * Clear user session (logout)
     */
    fun clearSession(context: Context) {
        Log.d(TAG, "==================== CLEARING USER SESSION ====================")
        getPrefs(context).edit().clear().apply()
        Log.d(TAG, "✓ Session cleared successfully")
    }
}
