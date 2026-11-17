// ===== android/app/build.gradle.kts =====
// 1) Add these lines at the VERY TOP of the file (above the plugins { } block):

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 2) Inside the existing android { ... } block, add signingConfigs ABOVE buildTypes:

android {
    // ... keep everything that is already here (namespace, compileSdk, defaultConfig ...)

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // 3) In buildTypes, REPLACE the debug signing line with the release one:
    buildTypes {
        release {
            // was: signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
