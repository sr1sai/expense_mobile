package com.example.expense_mobile.SMSHandling

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.expense_mobile.BuildConfig
import com.example.expense_mobile.R
import com.example.expense_mobile.utils.EnvConfig
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class SmsForegroundService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 2001 // Unique ID for SMS service
        private const val CHANNEL_ID = "sms_channel"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("SmsForegroundService", "==================== SERVICE CREATED ====================")
        Log.d("SmsForegroundService", "onCreate() called")
        
        // Create notification channel as fallback if MainActivity hasn't created it yet
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("SmsForegroundService", "Creating notification channel")
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SMS Listener",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("SmsForegroundService", "==================== SERVICE STARTED ====================")
        Log.d("SmsForegroundService", "onStartCommand() called with startId: $startId")
        
        // Verify SMS permission is granted
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) 
            != PackageManager.PERMISSION_GRANTED) {
            Log.e("SmsForegroundService", "SMS permission not granted")
            stopSelf(startId)
            return START_NOT_STICKY
        }
        Log.d("SmsForegroundService", "SMS permission verified")

        val sender = intent?.getStringExtra("sender") ?: run {
            Log.e("SmsForegroundService", "Sender is null, stopping service")
            return START_NOT_STICKY
        }
        val message = intent.getStringExtra("message") ?: ""
        val timestamp = intent.getLongExtra("timestamp", 0L)

        Log.d("SmsForegroundService", "Processing SMS - Sender: $sender, Message: $message, Timestamp: $timestamp")
        
        Log.d("SmsForegroundService", "Starting foreground with notification")
        startForeground(NOTIFICATION_ID, createNotification())

        sendToApi(sender, message, timestamp, startId)

        return START_NOT_STICKY
    }

    private fun createNotification(): Notification {
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("SMS Listener Active")
            .setContentText("Listening for incoming messages")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }

    private fun sendToApi(sender: String, message: String, timestamp: Long, startId: Int) {
        Log.d("SmsForegroundService", "==================== API CALL ====================")
        Log.d("SmsForegroundService", "sendToApi() called")
        try {
            // Build URL using environment configuration
            // Format: BASE_URL + AIController + ClassifyMessage
            Log.d("SmsForegroundService", "Building API URL...")
            val apiUrl = EnvConfig.buildApiUrl(
                context = applicationContext,
                controllerKey = "AIController",
                actionKey = "ClassifyMessage",
                isProduction = !BuildConfig.DEBUG
            )

            Log.d("SmsForegroundService", "API URL: $apiUrl")
            Log.d("SmsForegroundService", "Debug mode: ${BuildConfig.DEBUG}")

            // Generate a valid UUID for userId (backend expects Guid type)
            // Using a fixed UUID for "personal-device-001" - can be made dynamic later
            val userId = "12345678-1234-1234-1234-123456789012" // Valid UUID format
            
            // Convert Unix timestamp (milliseconds) to ISO 8601 DateTime string for C# backend
            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val timeString = dateFormat.format(Date(timestamp))
            
            val json = JSONObject().apply {
                put("userId", userId)
                put("sender", sender)
                put("message", message) // Backend validation expects "message"
                put("messageContent", message) // Keep this too for compatibility
                put("time", timeString) // ISO 8601 DateTime string
            }

            Log.d("SmsForegroundService", "JSON Payload: ${json.toString()}")

            val body = json.toString()
                .toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url(apiUrl)
                .post(body)
                .build()
            
            Log.d("SmsForegroundService", "Making HTTP POST request...")

            OkHttpClient().newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e("SmsForegroundService", "==================== API FAILURE ====================")
                    Log.e("SmsForegroundService", "API call failed: ${e.message}")
                    Log.e("SmsForegroundService", "Exception: ${e.javaClass.simpleName}")
                    e.printStackTrace()
                    Log.d("SmsForegroundService", "Stopping service (startId: $startId)")
                    stopSelf(startId)
                }
                override fun onResponse(call: Call, response: Response) {
                    Log.d("SmsForegroundService", "==================== API RESPONSE ====================")
                    Log.d("SmsForegroundService", "Response code: ${response.code}")
                    Log.d("SmsForegroundService", "Response message: ${response.message}")
                    response.body?.let {
                        val responseBody = it.string()
                        Log.d("SmsForegroundService", "Response body: $responseBody")
                    }
                    Log.d("SmsForegroundService", "Stopping service (startId: $startId)")
                    stopSelf(startId)
                }
            })
        } catch (e: Exception) {
            Log.e("SmsForegroundService", "==================== EXCEPTION ====================")
            Log.e("SmsForegroundService", "Error sending to API: ${e.message}")
            Log.e("SmsForegroundService", "Exception type: ${e.javaClass.simpleName}")
            e.printStackTrace()
            Log.d("SmsForegroundService", "Stopping service due to exception (startId: $startId)")
            stopSelf(startId)
        }
    }


    override fun onBind(intent: Intent?): IBinder? = null
}
