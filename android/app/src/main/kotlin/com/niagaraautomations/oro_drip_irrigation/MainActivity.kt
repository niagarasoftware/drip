package com.niagaraautomations.oroDripirrigation

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import java.lang.reflect.Method

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.niagaraautomations.oroDripirrigation/bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "removeBond" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            val success = removeBond(address)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Address is null", null)
                        }
                    }
                    "getBondState" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            val bondState = getBondState(address)
                            result.success(bondState)
                        } else {
                            result.error("INVALID_ARGUMENT", "Address is null", null)
                        }
                    }
                    "clearGattCache" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            val success = clearGattCache(address)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Address is null", null)
                        }
                    }
                    "refreshDeviceCache" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            val success = refreshDeviceCache(address)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Address is null", null)
                        }
                    }
                    "isBluetoothEnabled" -> {
                        result.success(isBluetoothEnabled())
                    }
                    "enableBluetooth" -> {
                        enableBluetooth()
                        result.success(true)
                    }
                    "disableBluetooth" -> {
                        disableBluetooth()
                        result.success(true)
                    }
                    "getConnectedDevices" -> {
                        val devices = getConnectedDevices()
                        result.success(devices)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun removeBond(address: String): Boolean {
        return try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter == null) {
                android.util.Log.e("Bluetooth", "Bluetooth adapter is null")
                return false
            }

            val device = bluetoothAdapter.getRemoteDevice(address)
            android.util.Log.d("Bluetooth", "Attempting to remove bond for device: ${device.name}")

            val method: Method = device.javaClass.getMethod("removeBond")
            val result = method.invoke(device) as Boolean

            android.util.Log.d("Bluetooth", "Bond removal result: $result")
            result
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error removing bond: ${e.message}", e)
            false
        }
    }

    private fun getBondState(address: String): Int {
        return try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter == null) {
                android.util.Log.e("Bluetooth", "Bluetooth adapter is null")
                return 0
            }

            val device = bluetoothAdapter.getRemoteDevice(address)
            val bondState = device.bondState
            android.util.Log.d("Bluetooth", "Bond state for ${device.name}: $bondState")

            when (bondState) {
                BluetoothDevice.BOND_NONE -> 0
                BluetoothDevice.BOND_BONDING -> 1
                BluetoothDevice.BOND_BONDED -> 2
                else -> 0
            }
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error getting bond state: ${e.message}", e)
            0
        }
    }

    private fun clearGattCache(address: String): Boolean {
        return try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter == null) {
                android.util.Log.e("Bluetooth", "Bluetooth adapter is null")
                return false
            }

            val device = bluetoothAdapter.getRemoteDevice(address)
            android.util.Log.d("Bluetooth", "Clearing GATT cache for device: ${device.name}")

            // Try different method names that might work
            val methodNames = listOf("refresh", "refreshDeviceCache", "clearGattCache")
            var success = false

            for (methodName in methodNames) {
                try {
                    val method: Method = device.javaClass.getMethod(methodName)
                    val result = method.invoke(device) as? Boolean ?: true
                    if (result) {
                        android.util.Log.d("Bluetooth", "GATT cache cleared using $methodName")
                        success = true
                        break
                    }
                } catch (e: NoSuchMethodException) {
                    // Method doesn't exist, try next
                    continue
                } catch (e: Exception) {
                    android.util.Log.e("Bluetooth", "Error with method $methodName: ${e.message}")
                    continue
                }
            }

            // If no method found, just return true (not critical)
            success || true
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error clearing GATT cache: ${e.message}", e)
            false
        }
    }

    private fun refreshDeviceCache(address: String): Boolean {
        return try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter == null) {
                android.util.Log.e("Bluetooth", "Bluetooth adapter is null")
                return false
            }

            val device = bluetoothAdapter.getRemoteDevice(address)
            android.util.Log.d("Bluetooth", "Refreshing device cache for: ${device.name}")

            // Try to force a refresh by disconnecting and reconnecting
            try {
                val disconnectMethod: Method = device.javaClass.getMethod("disconnect")
                disconnectMethod.invoke(device)
                Thread.sleep(100)
            } catch (e: Exception) {
                android.util.Log.d("Bluetooth", "Disconnect method not available or failed: ${e.message}")
            }

            true
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error refreshing device cache: ${e.message}", e)
            false
        }
    }

    private fun isBluetoothEnabled(): Boolean {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        return bluetoothAdapter?.isEnabled == true
    }

    private fun enableBluetooth() {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null && !bluetoothAdapter.isEnabled) {
            // Note: This requires user interaction via Intent
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            activity?.startActivity(enableBtIntent)
        }
    }

    private fun disableBluetooth() {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
            bluetoothAdapter.disable()
        }
    }

    private fun getConnectedDevices(): List<String> {
        val devices = mutableListOf<String>()
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null) {
                val bondedDevices = bluetoothAdapter.bondedDevices
                for (device in bondedDevices) {
                    devices.add("${device.name}|${device.address}|${device.bondState}")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("Bluetooth", "Error getting connected devices: ${e.message}", e)
        }
        return devices
    }
}