package com.oyaiz.apps.hapbox

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private val HAPTICS_CHANNEL = "com.oyaiz.apps.hapbox/haptics"
    private val SENSORS_CHANNEL = "com.oyaiz.apps.hapbox/sensors"

    private var vibrator: Vibrator? = null
    private var sensorManager: SensorManager? = null
    private var sensorEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initVibrator()
        initSensors(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HAPTICS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasVibrator" -> {
                    result.success(vibrator?.hasVibrator() ?: false)
                }
                "hasAmplitudeControl" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(vibrator?.hasAmplitudeControl() ?: false)
                    } else {
                        result.success(false)
                    }
                }
                "vibrateOneShot" -> {
                    val duration = (call.argument<Number>("duration") ?: 50).toLong().coerceIn(20, 2000)
                    val amplitude = (call.argument<Number>("amplitude") ?: 180).toInt().coerceIn(1, 255)
                    playOneShot(duration, amplitude)
                    result.success(true)
                }
                "vibrateWaveform" -> {
                    val rawTimings = call.argument<List<Number>>("timings") ?: listOf(0, 50)
                    val rawAmplitudes = call.argument<List<Number>>("amplitudes") ?: listOf(0, 180)
                    val repeat = (call.argument<Number>("repeat") ?: -1).toInt()

                    val timings = rawTimings.map { it.toLong() }.toLongArray()
                    val amplitudes = rawAmplitudes.map { it.toInt().coerceIn(0, 255) }.toIntArray()

                    playWaveform(timings, amplitudes, repeat)
                    result.success(true)
                }
                "vibratePredefined" -> {
                    val type = call.argument<String>("type") ?: "click"
                    val amplitude = call.argument<Number>("amplitude")?.toInt()
                    playPredefined(type, amplitude)
                    result.success(true)
                }
                "vibrateRamp" -> {
                    val startAmp = (call.argument<Number>("startAmplitude") ?: 10).toInt().coerceIn(0, 255)
                    val endAmp = (call.argument<Number>("endAmplitude") ?: 255).toInt().coerceIn(0, 255)
                    val durationMs = (call.argument<Number>("durationMs") ?: 600).toLong().coerceIn(50, 4000)
                    val curve = call.argument<String>("curve") ?: "linear"
                    playRamp(startAmp, endAmp, durationMs, curve)
                    result.success(true)
                }
                "setContinuous" -> {
                    val amplitude = (call.argument<Number>("amplitude") ?: 150).toInt().coerceIn(0, 255)
                    setContinuous(amplitude)
                    result.success(true)
                }
                "vibrateComposition" -> {
                    val primitives = call.argument<List<Map<String, Any>>>("primitives") ?: emptyList()
                    playComposition(primitives)
                    result.success(true)
                }
                "cancel" -> {
                    vibrator?.cancel()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initVibrator() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun initSensors(flutterEngine: FlutterEngine) {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SENSORS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorEventSink = events
                    val sensor = sensorManager?.getDefaultSensor(Sensor.TYPE_GRAVITY)
                        ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
                    sensor?.let {
                        sensorManager?.registerListener(this@MainActivity, it, SensorManager.SENSOR_DELAY_GAME)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    sensorEventSink = null
                    sensorManager?.unregisterListener(this@MainActivity)
                }
            }
        )
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            if (it.sensor.type == Sensor.TYPE_GRAVITY || it.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                val data = mapOf(
                    "x" to it.values[0].toDouble(),
                    "y" to it.values[1].toDouble(),
                    "z" to it.values[2].toDouble()
                )
                sensorEventSink?.success(data)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    /**
     * USAGE_MEDIA または USAGE_GAME を指定して、OSの「タッチバイブレーションOFF」設定による無視（ignored_for_settings）を完全に回避して確実に振動させる
     */
    private fun executeVibrate(effect: VibrationEffect) {
        val v = vibrator ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Android 13+ では VibrationAttributes.USAGE_MEDIA
                val attrs = VibrationAttributes.Builder()
                    .setUsage(VibrationAttributes.USAGE_MEDIA)
                    .build()
                v.vibrate(effect, attrs)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val audioAttrs = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .build()
                v.vibrate(effect, audioAttrs)
            } else {
                v.vibrate(effect)
            }
        } catch (_: Exception) {
            try {
                v.vibrate(effect)
            } catch (_: Exception) {}
        }
    }

    private fun playOneShot(duration: Long, amplitude: Int) {
        playWaveform(longArrayOf(0, duration), intArrayOf(0, amplitude), -1)
    }

    private fun playWaveform(timings: LongArray, amplitudes: IntArray, repeat: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val safeTimings: LongArray
                val safeAmplitudes: IntArray
                if (timings.isNotEmpty() && timings[0] > 0) {
                    safeTimings = LongArray(timings.size + 1).apply {
                        this[0] = 0L
                        System.arraycopy(timings, 0, this, 1, timings.size)
                    }
                    safeAmplitudes = IntArray(amplitudes.size + 1).apply {
                        this[0] = 0
                        System.arraycopy(amplitudes, 0, this, 1, amplitudes.size)
                    }
                } else {
                    safeTimings = timings
                    safeAmplitudes = amplitudes
                }

                val effect = VibrationEffect.createWaveform(safeTimings, safeAmplitudes, repeat)
                executeVibrate(effect)
            } catch (e: Exception) {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(timings, repeat)
            }
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(timings, repeat)
        }
    }

    private fun playPredefined(type: String, customAmplitude: Int? = null) {
        val scale = if (customAmplitude != null) {
            customAmplitude.toFloat().coerceIn(20f, 255f) / 255.0f
        } else {
            1.0f
        }

        fun scaled(baseAmp: Int): Int {
            return (baseAmp * scale).toInt().coerceIn(20, 255)
        }

        when (type.lowercase()) {
            "tick" -> {
                playWaveform(longArrayOf(0, 18), intArrayOf(0, scaled(160)), -1)
            }
            "click" -> {
                playWaveform(longArrayOf(0, 28), intArrayOf(0, scaled(220)), -1)
            }
            "heavy_click" -> {
                playWaveform(longArrayOf(0, 45), intArrayOf(0, scaled(255)), -1)
            }
            "double_click" -> {
                playWaveform(longArrayOf(0, 22, 35, 26), intArrayOf(0, scaled(200), 0, scaled(240)), -1)
            }
            "pop" -> {
                playWaveform(longArrayOf(0, 20, 15, 30), intArrayOf(0, scaled(180), 0, scaled(255)), -1)
            }
            "thud" -> {
                playWaveform(longArrayOf(0, 70), intArrayOf(0, scaled(255)), -1)
            }
            "laser" -> {
                playWaveform(longArrayOf(0, 25, 15, 35, 10, 45), intArrayOf(0, scaled(120), 0, scaled(190), 0, scaled(255)), -1)
            }
            "warp" -> {
                playWaveform(longArrayOf(0, 30, 20, 45, 15, 65), intArrayOf(0, scaled(100), 0, scaled(180), 0, scaled(255)), -1)
            }
            "drop" -> {
                playWaveform(longArrayOf(0, 60, 20, 30), intArrayOf(0, scaled(255), 0, scaled(130)), -1)
            }
            "glitch" -> {
                playWaveform(longArrayOf(0, 18, 12, 28, 10, 20, 12, 40), intArrayOf(0, scaled(220), 0, scaled(255), 0, scaled(180), 0, scaled(240)), -1)
            }
            "engine_rev" -> {
                playRamp(scaled(20), scaled(255), 900L, "easein")
            }
            "ocean_swell" -> {
                playRamp(scaled(15), scaled(255), 1400L, "swell")
            }
            "power_charge" -> {
                playRamp(scaled(20), scaled(255), 1000L, "easein")
            }
            "laser_beam" -> {
                playWaveform(longArrayOf(0, 800), intArrayOf(0, scaled(240)), -1)
            }
            "purr" -> {
                playRamp(scaled(30), scaled(180), 1600L, "surge")
            }
            else -> {
                playWaveform(longArrayOf(0, 30), intArrayOf(0, scaled(200)), -1)
            }
        }
    }

    private fun playRamp(startAmp: Int, endAmp: Int, durationMs: Long, curve: String) {
        val stepDuration = 18L
        val numSteps = (durationMs / stepDuration).toInt().coerceIn(4, 200)
        val timings = LongArray(numSteps + 1)
        val amplitudes = IntArray(numSteps + 1)
        timings[0] = 0L
        amplitudes[0] = 0

        for (i in 0 until numSteps) {
            val t = i.toFloat() / (numSteps - 1).toFloat()
            val factor = when (curve.lowercase()) {
                "easein" -> t * t
                "easeout" -> Math.sin(t * Math.PI / 2.0).toFloat()
                "easeinout" -> (0.5 * (1.0 - Math.cos(t * Math.PI))).toFloat()
                "swell", "sinewave" -> Math.sin(t * Math.PI).toFloat()
                "surge" -> Math.sin(t * Math.PI * 2.0).toFloat().coerceAtLeast(0f)
                else -> t
            }

            val amp = if (curve.lowercase() == "swell" || curve.lowercase() == "sinewave" || curve.lowercase() == "surge") {
                val minA = startAmp.toFloat()
                val maxA = endAmp.toFloat()
                (minA + (maxA - minA) * factor).toInt().coerceIn(0, 255)
            } else {
                (startAmp + (endAmp - startAmp) * factor).toInt().coerceIn(0, 255)
            }

            timings[i + 1] = stepDuration
            amplitudes[i + 1] = amp
        }

        playWaveform(timings, amplitudes, -1)
    }

    private fun setContinuous(amplitude: Int) {
        val safeAmp = amplitude.coerceIn(0, 255)
        if (safeAmp == 0) {
            vibrator?.cancel()
        } else {
            playWaveform(longArrayOf(0, 350), intArrayOf(0, safeAmp), -1)
        }
    }

    private fun playComposition(primitives: List<Map<String, Any>>) {
        if (primitives.isEmpty()) return

        val timings = mutableListOf<Long>()
        val amplitudes = mutableListOf<Int>()

        timings.add(0L)
        amplitudes.add(0)

        for (prim in primitives) {
            val typeStr = (prim["type"] as? String) ?: "click"
            val scale = ((prim["scale"] as? Number)?.toFloat() ?: 1.0f).coerceIn(0.2f, 1.0f)
            val delay = ((prim["delay"] as? Number)?.toLong() ?: 0L).coerceAtLeast(0L)
            val baseAmp = (scale * 255).toInt().coerceIn(50, 255)

            if (delay > 0) {
                timings.add(delay)
                amplitudes.add(0)
            }

            when (typeStr.lowercase()) {
                "tick" -> {
                    timings.add(18L)
                    amplitudes.add((baseAmp * 0.75).toInt().coerceIn(40, 255))
                }
                "low_tick" -> {
                    timings.add(22L)
                    amplitudes.add((baseAmp * 0.85).toInt().coerceIn(40, 255))
                }
                "thud" -> {
                    timings.add(65L)
                    amplitudes.add(baseAmp)
                }
                "quick_fall" -> {
                    timings.add(25L)
                    amplitudes.add(baseAmp)
                    timings.add(15L)
                    amplitudes.add(0)
                    timings.add(20L)
                    amplitudes.add((baseAmp * 0.6).toInt())
                }
                "quick_rise" -> {
                    timings.add(20L)
                    amplitudes.add((baseAmp * 0.6).toInt())
                    timings.add(15L)
                    amplitudes.add(0)
                    timings.add(30L)
                    amplitudes.add(baseAmp)
                }
                "slow_rise" -> {
                    timings.add(25L)
                    amplitudes.add((baseAmp * 0.5).toInt())
                    timings.add(15L)
                    amplitudes.add(0)
                    timings.add(45L)
                    amplitudes.add(baseAmp)
                }
                "spin" -> {
                    timings.add(20L)
                    amplitudes.add((baseAmp * 0.7).toInt())
                    timings.add(10L)
                    amplitudes.add(0)
                    timings.add(25L)
                    amplitudes.add(baseAmp)
                }
                else -> {
                    timings.add(28L)
                    amplitudes.add(baseAmp)
                }
            }
        }

        playWaveform(timings.toLongArray(), amplitudes.toIntArray(), -1)
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager?.unregisterListener(this)
    }
}
