package com.example.expense_mobile.utils

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Helper class to read environment configuration from JSON files in Flutter assets
 * This mimics the behavior of the Dart EnvLoader class for native Android code
 */
object EnvConfig {
    private var baseUrl: String? = null
    private var controllers: Map<String, String>? = null
    private var apiActions: Map<String, String>? = null
    private var isLoaded = false

    /**
     * Load environment configuration from assets
     * Reads from env.development.json or env.production.json
     */
    private fun loadEnv(context: Context, isProduction: Boolean = false) {
        if (isLoaded) {
            android.util.Log.d("EnvConfig", "Environment already loaded, skipping")
            return
        }

        android.util.Log.d("EnvConfig", "==================== LOADING ENV ====================")
        android.util.Log.d("EnvConfig", "Loading environment configuration...")
        android.util.Log.d("EnvConfig", "Is Production: $isProduction")
        
        val envFile = if (isProduction) {
            "flutter_assets/assets/env.production.json"
        } else {
            "flutter_assets/assets/env.development.json"
        }
        android.util.Log.d("EnvConfig", "Loading from file: $envFile")

        try {
            val inputStream = context.assets.open(envFile)
            val reader = BufferedReader(InputStreamReader(inputStream))
            val jsonString = reader.use { it.readText() }
            val jsonObject = JSONObject(jsonString)

            baseUrl = jsonObject.optString("BASE_URL", null)

            val controllersJson = jsonObject.optJSONObject("Controllers")
            controllers = controllersJson?.let {
                val map = mutableMapOf<String, String>()
                it.keys().forEach { key ->
                    map[key] = it.getString(key)
                }
                map
            }

            val actionsJson = jsonObject.optJSONObject("APIActions")
            apiActions = actionsJson?.let {
                val map = mutableMapOf<String, String>()
                it.keys().forEach { key ->
                    map[key] = it.getString(key)
                }
                map
            }

            android.util.Log.d("EnvConfig", "Environment loaded successfully")
            android.util.Log.d("EnvConfig", "BASE_URL: $baseUrl")
            android.util.Log.d("EnvConfig", "Controllers loaded: ${controllers?.size ?: 0}")
            android.util.Log.d("EnvConfig", "API Actions loaded: ${apiActions?.size ?: 0}")
            isLoaded = true
        } catch (e: Exception) {
            android.util.Log.e("EnvConfig", "==================== ERROR ====================")
            android.util.Log.e("EnvConfig", "Error loading $envFile: ${e.message}")
            android.util.Log.e("EnvConfig", "Exception type: ${e.javaClass.simpleName}")
            e.printStackTrace()
            throw Exception("Failed to load environment configuration: ${e.message}")
        }
    }

    /**
     * Get base URL from environment config
     */
    fun getBaseUrl(context: Context, isProduction: Boolean = false): String {
        loadEnv(context, isProduction)
        return baseUrl ?: throw Exception("BASE_URL not found in environment file")
    }

    /**
     * Get controller path by key
     */
    fun getController(context: Context, key: String, isProduction: Boolean = false): String {
        loadEnv(context, isProduction)
        return controllers?.get(key) 
            ?: throw Exception("Controller '$key' not found in environment file")
    }

    /**
     * Get API action path by key
     */
    fun getAction(context: Context, key: String, isProduction: Boolean = false): String {
        loadEnv(context, isProduction)
        return apiActions?.get(key) 
            ?: throw Exception("API Action '$key' not found in environment file")
    }

    /**
     * Build complete API URL
     * Format: baseUrl + controller + action
     */
    fun buildApiUrl(
        context: Context, 
        controllerKey: String, 
        actionKey: String, 
        isProduction: Boolean = false
    ): String {
        android.util.Log.d("EnvConfig", "Building API URL for controller: $controllerKey, action: $actionKey")
        val base = getBaseUrl(context, isProduction)
        val controller = getController(context, controllerKey, isProduction)
        val action = getAction(context, actionKey, isProduction)
        val fullUrl = "$base$controller$action"
        android.util.Log.d("EnvConfig", "Complete URL: $fullUrl")
        return fullUrl
    }
}
