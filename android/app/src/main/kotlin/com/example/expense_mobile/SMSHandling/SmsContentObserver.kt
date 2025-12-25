package com.example.expense_mobile.SMSHandling

import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.util.Log

/**
 * ContentObserver that monitors the SMS database for new incoming messages.
 * This approach works regardless of RCS status or default SMS app,
 * as it directly monitors the SMS content provider.
 */
class SmsContentObserver(private val context: Context) : ContentObserver(Handler(Looper.getMainLooper())) {

    companion object {
        private const val TAG = "SmsContentObserver"
        private val SMS_INBOX_URI: Uri = Uri.parse("content://sms/inbox")
        private var lastProcessedTimestamp: Long = 0
    }

    init {
        // Initialize with current time to avoid processing old messages
        lastProcessedTimestamp = System.currentTimeMillis()
        Log.d(TAG, "==================== OBSERVER INITIALIZED ====================")
        Log.d(TAG, "Last processed timestamp initialized: $lastProcessedTimestamp")
        
        // Test database access on initialization
        testDatabaseAccess()
    }

    override fun onChange(selfChange: Boolean) {
        super.onChange(selfChange)
        Log.d(TAG, "==================== SMS DATABASE CHANGE DETECTED ====================")
        Log.d(TAG, "onChange() called with selfChange: $selfChange")
        
        // Query the SMS inbox for the most recent message
        val message = getLatestSms()
        if (message != null) {
            Log.d(TAG, "New SMS detected - processing...")
            processNewSms(message)
        } else {
            Log.d(TAG, "No new SMS found or query failed")
        }
    }

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        super.onChange(selfChange, uri)
        Log.d(TAG, "==================== SMS DATABASE CHANGE DETECTED (WITH URI) ====================")
        Log.d(TAG, "onChange() called with selfChange: $selfChange, uri: $uri")
        
        // Query the SMS inbox for the most recent message
        val message = getLatestSms()
        if (message != null) {
            Log.d(TAG, "New SMS detected - processing...")
            processNewSms(message)
        } else {
            Log.d(TAG, "No new SMS found or query failed")
        }
    }

    /**
     * Test database access on initialization
     */
    private fun testDatabaseAccess() {
        Log.d(TAG, "==================== TESTING DATABASE ACCESS ====================")
        try {
            val cursor = context.contentResolver.query(
                SMS_INBOX_URI,
                arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.DATE),
                null,
                null,
                "${Telephony.Sms.DATE} DESC LIMIT 1"
            )
            
            if (cursor != null) {
                val count = cursor.count
                Log.d(TAG, "Database access successful. Total messages in inbox: $count")
                if (cursor.moveToFirst()) {
                    val dateIndex = cursor.getColumnIndex(Telephony.Sms.DATE)
                    val lastMsgTimestamp = cursor.getLong(dateIndex)
                    Log.d(TAG, "Most recent SMS timestamp: $lastMsgTimestamp")
                }
                cursor.close()
            } else {
                Log.e(TAG, "Database access failed - cursor is null")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Database access error: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Manual check for new SMS (polling method)
     * Call this periodically as fallback if ContentObserver doesn't work
     */
    fun checkForNewMessages() {
        // Reduced logging for polling - only log when new message found
        val message = getLatestSms()
        if (message != null) {
            Log.d(TAG, "✓ New message found via polling - processing...")
            processNewSms(message)
        }
    }

    /**
     * Query the SMS inbox for the most recent message
     */
    private fun getLatestSms(): SmsMessage? {
        // Reduced logging - only log details when new message found
        var cursor: Cursor? = null
        try {
            val projection = arrayOf(
                Telephony.Sms.ADDRESS,      // Sender phone number
                Telephony.Sms.BODY,         // Message content
                Telephony.Sms.DATE,         // Timestamp in milliseconds
                Telephony.Sms.TYPE          // Message type (1=inbox, 2=sent, etc.)
            )

            // Query only inbox messages, sorted by date descending (newest first)
            cursor = context.contentResolver.query(
                SMS_INBOX_URI,
                projection,
                "${Telephony.Sms.TYPE} = ?",
                arrayOf(Telephony.Sms.MESSAGE_TYPE_INBOX.toString()),
                "${Telephony.Sms.DATE} DESC LIMIT 1"
            )

            if (cursor != null && cursor.moveToFirst()) {
                val addressIndex = cursor.getColumnIndex(Telephony.Sms.ADDRESS)
                val bodyIndex = cursor.getColumnIndex(Telephony.Sms.BODY)
                val dateIndex = cursor.getColumnIndex(Telephony.Sms.DATE)

                val sender = cursor.getString(addressIndex) ?: ""
                val message = cursor.getString(bodyIndex) ?: ""
                val timestamp = cursor.getLong(dateIndex)

                // Check if this message is newer than the last processed one
                if (timestamp > lastProcessedTimestamp) {
                    Log.d(TAG, "==================== NEW SMS FOUND ====================")
                    Log.d(TAG, "Sender: $sender")
                    Log.d(TAG, "Message: ${message.take(50)}${if (message.length > 50) "..." else ""}")
                    Log.d(TAG, "Timestamp: $timestamp")
                    Log.d(TAG, "✓ New message detected (timestamp: $timestamp > $lastProcessedTimestamp)")
                    lastProcessedTimestamp = timestamp
                    return SmsMessage(sender, message, timestamp)
                }
                // Old message - silently skip (no logs to reduce noise)
            }
        } catch (e: Exception) {
            Log.e(TAG, "==================== ERROR ====================")
            Log.e(TAG, "Error querying SMS database: ${e.message}")
            e.printStackTrace()
        } finally {
            cursor?.close()
        }
        
        return null
    }

    /**
     * Process new SMS by starting the foreground service
     */
    private fun processNewSms(sms: SmsMessage) {
        Log.d(TAG, "==================== PROCESSING NEW SMS ====================")
        Log.d(TAG, "Sender: ${sms.sender}")
        Log.d(TAG, "Message: ${sms.message}")
        Log.d(TAG, "Timestamp: ${sms.timestamp}")

        // Enqueue message to prevent duplicates
        Log.d(TAG, "Enqueueing message to queue manager")
        SmsQueueManager.enqueue(context, sms.sender, sms.message, sms.timestamp)
        Log.d(TAG, "Message enqueued successfully")
    }

    // Old service start code - replaced with queue manager
    private fun processNewSmsOld(sms: SmsMessage) {
        val serviceIntent = Intent(context, SmsForegroundService::class.java).apply {
            putExtra("sender", sms.sender)
            putExtra("message", sms.message)
            putExtra("timestamp", sms.timestamp)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting foreground service (API >= O)")
                context.startForegroundService(serviceIntent)
            } else {
                Log.d(TAG, "Starting service (API < O)")
                context.startService(serviceIntent)
            }
            Log.d(TAG, "Service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "==================== ERROR ====================")
            Log.e(TAG, "Error starting service: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * Data class to hold SMS message details
     */
    private data class SmsMessage(
        val sender: String,
        val message: String,
        val timestamp: Long
    )
}
