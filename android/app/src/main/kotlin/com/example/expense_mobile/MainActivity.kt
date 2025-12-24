package com.example.expense_mobile

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.expense_mobile.SMSHandling.SmsContentObserver
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private var smsObserver: SmsContentObserver? = null
    private val pollingHandler = Handler(Looper.getMainLooper())
    private val pollingInterval = 5000L // 5 seconds
    
    private val pollingRunnable = object : Runnable {
        override fun run() {
            Log.d("MainActivity", "Polling for new SMS messages...")
            smsObserver?.checkForNewMessages()
            pollingHandler.postDelayed(this, pollingInterval)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "==================== APP STARTED ====================")
        Log.d("MainActivity", "onCreate() called")
        Log.d("MainActivity", "Android SDK version: ${Build.VERSION.SDK_INT}")
        
        // Check SMS permissions
        checkPermissions()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("MainActivity", "Creating notification channel for SMS")
            val channel = NotificationChannel(
                "sms_channel",
                "SMS Listener",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            Log.d("MainActivity", "Notification channel 'sms_channel' created successfully")
        }
        
        // Register SMS content observer
        registerSmsObserver()
        
        Log.d("MainActivity", "MainActivity initialization complete")
    }

    override fun onDestroy() {
        super.onDestroy()
        // Stop polling
        stopSmsPolling()
        // Unregister SMS content observer
        unregisterSmsObserver()
    }
    
    override fun onResume() {
        super.onResume()
        // Start polling when app is in foreground
        startSmsPolling()
    }
    
    override fun onPause() {
        super.onPause()
        // Stop polling when app goes to background
        stopSmsPolling()
    }
    
    private fun checkPermissions() {
        Log.d("MainActivity", "==================== PERMISSION STATUS ====================")
        
        val smsReceivePermission = ContextCompat.checkSelfPermission(
            this, 
            Manifest.permission.RECEIVE_SMS
        )
        val smsReadPermission = ContextCompat.checkSelfPermission(
            this, 
            Manifest.permission.READ_SMS
        )
        val notificationPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            )
        } else {
            PackageManager.PERMISSION_GRANTED
        }
        
        Log.d("MainActivity", "RECEIVE_SMS: ${if (smsReceivePermission == PackageManager.PERMISSION_GRANTED) "GRANTED ✓" else "DENIED ✗"}")
        Log.d("MainActivity", "READ_SMS: ${if (smsReadPermission == PackageManager.PERMISSION_GRANTED) "GRANTED ✓" else "DENIED ✗"}")
        Log.d("MainActivity", "POST_NOTIFICATIONS: ${if (notificationPermission == PackageManager.PERMISSION_GRANTED) "GRANTED ✓" else "DENIED ✗"}")
        Log.d("MainActivity", "========================================================")
    }
    
    /**
     * Register SMS content observer to monitor SMS database changes
     */
    private fun registerSmsObserver() {
        Log.d("MainActivity", "==================== REGISTERING SMS OBSERVER ====================")
        
        // Check if we have READ_SMS permission before registering
        val readSmsPermission = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        )
        
        if (readSmsPermission != PackageManager.PERMISSION_GRANTED) {
            Log.e("MainActivity", "READ_SMS permission not granted, cannot register observer")
            return
        }
        
        try {
            smsObserver = SmsContentObserver(this)
            
            // Register with multiple URIs for better compatibility
            val smsUri = Uri.parse("content://sms/")
            val inboxUri = Uri.parse("content://sms/inbox")
            
            contentResolver.registerContentObserver(
                smsUri,
                true,  // notifyForDescendants - observe all SMS URIs
                smsObserver!!
            )
            Log.d("MainActivity", "SMS ContentObserver registered for content://sms/")
            
            contentResolver.registerContentObserver(
                inboxUri,
                true,
                smsObserver!!
            )
            Log.d("MainActivity", "SMS ContentObserver registered for content://sms/inbox")
            Log.d("MainActivity", "ContentObserver registration complete")
            
            // Start polling as fallback (for Oppo/ColorOS devices that block ContentObserver)
            Log.d("MainActivity", "Starting SMS polling as fallback mechanism...")
            startSmsPolling()
        } catch (e: Exception) {
            Log.e("MainActivity", "==================== ERROR ====================")
            Log.e("MainActivity", "Error registering SMS observer: ${e.message}")
            e.printStackTrace()
        }
    }
    
    /**
     * Start periodic polling for new SMS messages
     * Fallback mechanism for devices that block ContentObserver notifications
     */
    private fun startSmsPolling() {
        Log.d("MainActivity", "==================== STARTING SMS POLLING ====================")
        Log.d("MainActivity", "Polling interval: ${pollingInterval}ms (${pollingInterval/1000}s)")
        stopSmsPolling() // Ensure no duplicate polling
        pollingHandler.postDelayed(pollingRunnable, pollingInterval)
        Log.d("MainActivity", "Polling started successfully")
    }
    
    /**
     * Stop SMS polling
     */
    private fun stopSmsPolling() {
        pollingHandler.removeCallbacks(pollingRunnable)
        Log.d("MainActivity", "Polling stopped")
    }
    
    /**
     * Unregister SMS content observer when activity is destroyed
     */
    private fun unregisterSmsObserver() {
        Log.d("MainActivity", "==================== UNREGISTERING SMS OBSERVER ====================")
        
        smsObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
                Log.d("MainActivity", "SMS ContentObserver unregistered successfully")
            } catch (e: Exception) {
                Log.e("MainActivity", "==================== ERROR ====================")
                Log.e("MainActivity", "Error unregistering SMS observer: ${e.message}")
                e.printStackTrace()
            }
        }
        smsObserver = null
    }

}
