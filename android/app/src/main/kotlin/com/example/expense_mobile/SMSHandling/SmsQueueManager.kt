package com.example.expense_mobile.SMSHandling

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

/**
 * Singleton queue manager to prevent duplicate SMS processing
 * Deduplicates messages from BroadcastReceiver, ContentObserver, and polling
 */
object SmsQueueManager {
    private const val TAG = "SmsQueueManager"
    
    // Queue of pending messages
    private val messageQueue = ArrayDeque<SmsMessage>()
    
    // Track processed messages (key: unique message ID, value: timestamp when processed)
    private val processedMessages = ConcurrentHashMap<String, Long>()
    
    // Handler for processing queue on main thread
    private val handler = Handler(Looper.getMainLooper())
    
    // Lock for thread-safe queue operations
    private val queueLock = Any()
    
    // Flag to track if queue processing is active
    private var isProcessing = false
    
    // Clean up old processed messages after 5 minutes
    private const val CLEANUP_INTERVAL = 5 * 60 * 1000L // 5 minutes
    
    init {
        // Schedule periodic cleanup of old processed messages
        scheduleCleanup()
    }
    
    /**
     * Enqueue a new SMS message for processing
     * Automatically deduplicates based on sender, message content, and timestamp
     */
    fun enqueue(context: Context, sender: String, message: String, timestamp: Long) {
        Log.d(TAG, "==================== ENQUEUE SMS ====================")
        Log.d(TAG, "Sender: $sender")
        Log.d(TAG, "Message: ${message.take(50)}${if (message.length > 50) "..." else ""}")
        Log.d(TAG, "Timestamp: $timestamp")
        
        val messageId = generateMessageId(sender, message, timestamp)
        Log.d(TAG, "Message ID: $messageId")
        
        synchronized(queueLock) {
            // Check if message was already processed recently
            if (processedMessages.containsKey(messageId)) {
                val processedTime = processedMessages[messageId] ?: 0L
                val timeSinceProcessed = System.currentTimeMillis() - processedTime
                Log.d(TAG, "⊗ Message already processed ${timeSinceProcessed}ms ago - SKIPPING")
                return
            }
            
            // Check if message is already in queue
            val alreadyQueued = messageQueue.any { 
                generateMessageId(it.sender, it.message, it.timestamp) == messageId 
            }
            
            if (alreadyQueued) {
                Log.d(TAG, "⊗ Message already in queue - SKIPPING")
                return
            }
            
            // Add to queue
            val smsMessage = SmsMessage(context, sender, message, timestamp)
            messageQueue.add(smsMessage)
            Log.d(TAG, "✓ Message added to queue. Queue size: ${messageQueue.size}")
        }
        
        // Start processing if not already active
        processQueue()
    }
    
    /**
     * Process messages from queue sequentially
     */
    private fun processQueue() {
        handler.post {
            synchronized(queueLock) {
                if (isProcessing) {
                    Log.d(TAG, "Queue processing already active")
                    return@post
                }
                
                if (messageQueue.isEmpty()) {
                    Log.d(TAG, "Queue is empty")
                    return@post
                }
                
                isProcessing = true
            }
            
            processNextMessage()
        }
    }
    
    /**
     * Process the next message in queue
     */
    private fun processNextMessage() {
        val message: SmsMessage? = synchronized(queueLock) {
            if (messageQueue.isEmpty()) {
                isProcessing = false
                Log.d(TAG, "Queue processing complete")
                return
            }
            messageQueue.removeFirstOrNull()
        }
        
        message?.let {
            Log.d(TAG, "==================== PROCESSING SMS ====================")
            Log.d(TAG, "Sender: ${it.sender}")
            Log.d(TAG, "Message: ${it.message.take(50)}${if (it.message.length > 50) "..." else ""}")
            Log.d(TAG, "Timestamp: ${it.timestamp}")
            
            val messageId = generateMessageId(it.sender, it.message, it.timestamp)
            
            // Mark as processed
            processedMessages[messageId] = System.currentTimeMillis()
            
            // Start foreground service
            startService(it)
            
            // Process next message after a short delay (500ms) to avoid overwhelming the system
            handler.postDelayed({
                processNextMessage()
            }, 500)
        }
    }
    
    /**
     * Start the foreground service to send SMS to API
     */
    private fun startService(sms: SmsMessage) {
        val serviceIntent = Intent(sms.context, SmsForegroundService::class.java).apply {
            putExtra("sender", sms.sender)
            putExtra("message", sms.message)
            putExtra("timestamp", sms.timestamp)
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "Starting foreground service (API >= O)")
                sms.context.startForegroundService(serviceIntent)
            } else {
                Log.d(TAG, "Starting service (API < O)")
                sms.context.startService(serviceIntent)
            }
            Log.d(TAG, "✓ Service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "✗ Failed to start service: ${e.message}")
            e.printStackTrace()
        }
    }
    
    /**
     * Generate unique message ID based on sender, content, and timestamp
     * Round timestamp to nearest second to handle slight timing differences
     */
    private fun generateMessageId(sender: String, message: String, timestamp: Long): String {
        // Round timestamp to nearest second (1000ms) to handle timing differences
        // between BroadcastReceiver PDU timestamp and database timestamp
        val roundedTimestamp = (timestamp / 1000) * 1000
        return "$sender:${message.hashCode()}:$roundedTimestamp"
    }
    
    /**
     * Schedule periodic cleanup of old processed messages
     */
    private fun scheduleCleanup() {
        handler.postDelayed({
            cleanupOldMessages()
            scheduleCleanup() // Reschedule
        }, CLEANUP_INTERVAL)
    }
    
    /**
     * Remove processed messages older than 5 minutes
     */
    private fun cleanupOldMessages() {
        val now = System.currentTimeMillis()
        val threshold = now - CLEANUP_INTERVAL
        
        val iterator = processedMessages.entries.iterator()
        var removed = 0
        
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.value < threshold) {
                iterator.remove()
                removed++
            }
        }
        
        if (removed > 0) {
            Log.d(TAG, "Cleanup: Removed $removed old message(s). Remaining: ${processedMessages.size}")
        }
    }
    
    /**
     * Get current queue size (for debugging)
     */
    fun getQueueSize(): Int = synchronized(queueLock) { messageQueue.size }
    
    /**
     * Get number of processed messages tracked (for debugging)
     */
    fun getProcessedCount(): Int = processedMessages.size
    
    /**
     * Data class to hold SMS message information
     */
    private data class SmsMessage(
        val context: Context,
        val sender: String,
        val message: String,
        val timestamp: Long
    )
}
