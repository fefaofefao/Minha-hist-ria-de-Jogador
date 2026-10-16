package com.fefaofefao.minhahistoria.firebase

import android.os.Bundle
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject

/**
 * Plugin Android (Godot v2) com Firebase Analytics, Crashlytics e Remote Config.
 * Singleton no GDScript: Engine.get_singleton("MinhaHistoriaFirebase").
 *
 * A inicialização é feita com as chaves de config/servicos.cfg (sem precisar
 * do plugin Gradle google-services), via inicializar(appId, apiKey, projectId).
 */
class MinhaHistoriaFirebase(godot: Godot) : GodotPlugin(godot) {

    private var analytics: FirebaseAnalytics? = null
    private var remoteConfig: FirebaseRemoteConfig? = null

    override fun getPluginName() = "MinhaHistoriaFirebase"

    override fun getPluginSignals() = setOf(
        SignalInfo("remote_config_fetched", String::class.java)
    )

    @UsedByGodot
    fun inicializar(appId: String, apiKey: String, projectId: String) {
        val ctx = activity ?: return
        try {
            if (FirebaseApp.getApps(ctx).isEmpty()) {
                val opcoes = FirebaseOptions.Builder()
                    .setApplicationId(appId)
                    .setApiKey(apiKey)
                    .setProjectId(projectId)
                    .build()
                FirebaseApp.initializeApp(ctx, opcoes)
            }
            analytics = FirebaseAnalytics.getInstance(ctx)
            remoteConfig = FirebaseRemoteConfig.getInstance().also {
                it.setConfigSettingsAsync(
                    FirebaseRemoteConfigSettings.Builder().setMinimumFetchIntervalInSeconds(3600).build()
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao inicializar o Firebase", e)
        }
    }

    @UsedByGodot
    fun logEvent(nome: String, paramsJson: String) {
        val a = analytics ?: return
        val bundle = Bundle()
        try {
            val json = JSONObject(paramsJson)
            for (chave in json.keys()) {
                when (val v = json.get(chave)) {
                    is Int -> bundle.putLong(chave, v.toLong())
                    is Long -> bundle.putLong(chave, v)
                    is Double -> bundle.putDouble(chave, v)
                    is Boolean -> bundle.putLong(chave, if (v) 1 else 0)
                    else -> bundle.putString(chave, v.toString().take(100))
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Parâmetros inválidos para $nome", e)
        }
        a.logEvent(nome.take(40), bundle)
    }

    @UsedByGodot
    fun setUserProperty(nome: String, valor: String) {
        analytics?.setUserProperty(nome.take(24), valor.take(36))
    }

    @UsedByGodot
    fun recordError(mensagem: String) {
        try {
            FirebaseCrashlytics.getInstance().recordException(RuntimeException(mensagem))
        } catch (e: Exception) {
            Log.w(TAG, "Crashlytics indisponível", e)
        }
    }

    @UsedByGodot
    fun fetchRemoteConfig(padroesJson: String) {
        val rc = remoteConfig ?: return
        val padroes = HashMap<String, Any>()
        try {
            val json = JSONObject(padroesJson)
            for (chave in json.keys()) padroes[chave] = json.get(chave)
        } catch (_: Exception) {
        }
        rc.setDefaultsAsync(padroes)
        rc.fetchAndActivate().addOnCompleteListener {
            val saida = JSONObject()
            for ((chave, valor) in rc.all) {
                val texto = valor.asString()
                saida.put(chave, texto.toDoubleOrNull() ?: texto)
            }
            emitSignal("remote_config_fetched", saida.toString())
        }
    }

    companion object {
        private const val TAG = "MinhaHistoriaFirebase"
    }
}
