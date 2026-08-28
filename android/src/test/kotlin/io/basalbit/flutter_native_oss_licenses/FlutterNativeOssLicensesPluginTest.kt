package io.basalbit.flutter_native_oss_licenses

import java.io.ByteArrayInputStream
import java.io.FileNotFoundException
import kotlin.test.Test
import kotlin.test.assertEquals

internal class FlutterNativeOssLicensesPluginTest {
    @Test
    fun readNativeLicensePayloadReadsNamespacedAsset() {
        val payload =
            readNativeLicensePayload {
                ByteArrayInputStream("[{\"text\":\"License\"}]".toByteArray())
            }

        assertEquals("[{\"text\":\"License\"}]", payload)
    }

    @Test
    fun readNativeLicensePayloadReturnsEmptyArrayWhenSetupAssetIsMissing() {
        assertEquals("[]", readNativeLicensePayload { throw FileNotFoundException() })
    }
}
