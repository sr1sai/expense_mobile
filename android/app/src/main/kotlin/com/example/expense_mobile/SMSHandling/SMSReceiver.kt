package com.example.expense_mobile.SMSHandling

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log
import androidx.core.content.ContextCompat

class SMSReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SMSReceiver", "==================== SMS RECEIVED ====================")
        Log.d("SMSReceiver", "onReceive() called")
        
        // Verify SMS permission is granted
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECEIVE_SMS) 
            != PackageManager.PERMISSION_GRANTED) {
            Log.e("SMSReceiver", "SMS permission not granted")
            return
        }
        Log.d("SMSReceiver", "SMS permission verified")

        val bundle = intent.extras ?: run {
            Log.e("SMSReceiver", "Intent extras is null")
            return
        }
        val pdus = bundle["pdus"] as? Array<*> ?: run {
            Log.e("SMSReceiver", "PDUs array is null")
            return
        }
        val format = bundle.getString("format")
        Log.d("SMSReceiver", "Processing ${pdus.size} SMS PDU(s) with format: $format")

        for (pdu in pdus) {
            val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                SmsMessage.createFromPdu(pdu as ByteArray, format)
            } else {
                @Suppress("DEPRECATION")
                SmsMessage.createFromPdu(pdu as ByteArray)
            }
            val sender = sms.originatingAddress ?: ""
            val message = sms.messageBody ?: ""
            val timestamp = sms.timestampMillis

            Log.d("SMSReceiver", "==================== SMS DETAILS ====================")
            Log.d("SMSReceiver", "Sender: $sender")
            Log.d("SMSReceiver", "Message: $message")
            Log.d("SMSReceiver", "Timestamp: $timestamp")

            // Enqueue message to prevent duplicates
            Log.d("SMSReceiver", "Enqueueing message to queue manager")
            SmsQueueManager.enqueue(context, sender, message, timestamp)
            Log.d("SMSReceiver", "Message enqueued successfully")
        }
    }
}
