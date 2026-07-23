package dev.busung.s25uroot

import android.content.Context
import android.system.Os
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

data class VerifiedPayloads(
    val profile: TargetProfile,
    val exploit: File,
    val kernelSu: File,
)

class PayloadRepository(private val context: Context) {
    var enableProxy: Boolean = true

    // ===================== 请在此处填入你仓库 main 分支最新的 40 位 Commit 哈希 =====================
    private val FIXED_MAIN_COMMIT = "在此处填入main分支最新40位commit哈希"

    fun loadTargets(): List<TargetProfile> {
        val manifestBytes = downloadBytes(rawUrl(FIXED_MAIN_COMMIT, "Root-My-Galaxy-Payloads-main/support/targets-v2.json"), MAX_MANIFEST_BYTES)
        return SupportManifest.parse(manifestBytes).targets.map { profile -> profile.copy(
            exploit = profile.exploit.copy(url = pinArtifactUrl(profile.exploit.url, FIXED_MAIN_COMMIT)),
            kernelSu = profile.kernelSu.copy(
                artifact = profile.kernelSu.artifact.copy(
                    url = pinArtifactUrl(profile.kernelSu.artifact.url, FIXED_MAIN_COMMIT),
                ),
            ),
        ) }
    }

    fun resolveTarget(snapshot: DeviceSnapshot): TargetProfile = loadTargets()
        .firstOrNull { it.matches(snapshot) }
        ?: error(context.getString(R.string.repo_no_profile))

    fun resolveTarget(profileId: String): TargetProfile = loadTargets()
        .firstOrNull { it.profileId == profileId }
        ?: error(context.getString(R.string.repo_profile_missing, profileId))

    fun download(profile: TargetProfile, onProgress: (String) -> Unit): VerifiedPayloads {
        val directory = File(context.filesDir, "payloads/${profile.profileId}").apply { mkdirs() }
        val exploit = downloadArtifact(
            profile.exploit,
            File(directory, "cve-2026-43499-app.so"),
            context.getString(R.string.artifact_exploit),
            onProgress,
        )
        val kernelSu = downloadArtifact(
            profile.kernelSu.artifact,
            File(directory, "ksud-s25u-kdp"),
            context.getString(R.string.artifact_kernelsu),
            onProgress,
        )
        Os.chmod(exploit.absolutePath, 0b100100100)
        Os.chmod(kernelSu.absolutePath, 0b100100100)
        return VerifiedPayloads(profile, exploit, kernelSu)
    }

    private fun downloadArtifact(
        artifact: RemoteArtifact,
        destination: File,
        label: String,
        onProgress: (String) -> Unit,
    ): File {
        onProgress(context.getString(R.string.repo_downloading, label))
        val temporary = File(destination.parentFile, "${destination.name}.part")
        val connection = open(wrapUrl(artifact.url))
        require(connection.contentLengthLong == -1L || connection.contentLengthLong == artifact.size) {
            context.getString(R.string.repo_size_mismatch, label)
        }
        var total = 0L
        connection.inputStream.use { input ->
            FileOutputStream(temporary).use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    total += count
                    require(total <= artifact.size) {
                        context.getString(R.string.repo_size_exceeded, label)
                    }
                    output.write(buffer, 0, count)
                }
                output.fd.sync()
            }
        }
        connection.disconnect()
        require(total == artifact.size) { context.getString(R.string.repo_incomplete, label) }
        if (destination.exists()) destination.delete()
        require(temporary.renameTo(destination)) {
            context.getString(R.string.repo_finalize_failed, label)
        }
        onProgress(context.getString(R.string.repo_verified, label))
        return destination
    }

    private fun rawUrl(commit: String, path: String) = "$RAW_REPOSITORY/$commit/$path"

    private fun pinArtifactUrl(url: String, commit: String): String {
        // 放宽前缀检查，兼容不同分支或自定义路径，直接重写并绑定当前的 FIXED_MAIN_COMMIT
        val relativePath = when {
            url.contains("Root-My-Galaxy-Payloads-main/") -> url.substringAfter("Root-My-Galaxy-Payloads-main/")
            url.contains("artifacts/") -> "artifacts/" + url.substringAfter("artifacts/")
            url.contains("kernelsu/") -> "kernelsu/" + url.substringAfter("kernelsu/")
            else -> url.substringAfterLast("/")
        }
        return "$RAW_REPOSITORY/$commit/Root-My-Galaxy-Payloads-main/$relativePath".replace("(?<!g:/)(?<!s:)//".toRegex(), "/")
    }

    private fun downloadBytes(url: String, maximum: Int): ByteArray {
        val connection = open(wrapUrl(url))
        val bytes = connection.inputStream.use { input ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                require(output.size() + count <= maximum) {
                    context.getString(R.string.repo_response_too_large)
                }
                output.write(buffer, 0, count)
            }
            output.toByteArray()
        }
        connection.disconnect()
        return bytes
    }

    private fun open(url: String): HttpURLConnection =
        (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 15_000
            readTimeout = 60_000
            instanceFollowRedirects = true
            setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
            connect()
            require(responseCode == HttpURLConnection.HTTP_OK) { "HTTP $responseCode" }
        }

    private fun wrapUrl(originalUrl: String): String {
        if (!enableProxy) return originalUrl
        if (originalUrl.startsWith("https://ghproxy.com/")) return originalUrl
        return "https://ghproxy.com/$originalUrl"
    }

    companion object {
        private const val RAW_REPOSITORY =
            "https://raw.githubusercontent.com/sir990928/-"
        private const val MUTABLE_RAW_PREFIX = "$RAW_REPOSITORY/main/Root-My-Galaxy-Payloads-main/"
        private const val MAX_MANIFEST_BYTES = 256 * 1024
    }
}
