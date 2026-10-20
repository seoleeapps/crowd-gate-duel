plugins { id("com.android.library") }
val engineVersion: String = rootProject.file("../../../build.env").readLines()
    .first { it.startsWith("GODOT_VERSION=") }.substringAfter("=")
val adsAppId = providers.environmentVariable("ADMOB_APP_ID")
    .orElse("ca-app-pub-3940256099942544~3347511713")
android {
    namespace = "com.seoleeapps.crowdgateduel.platform"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
        manifestPlaceholders["admobAppId"] = adsAppId.get()
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    compileOnly("org.godotengine:godot:$engineVersion.stable")
    implementation("com.google.android.gms:play-services-ads:25.5.0")
    implementation("com.google.android.ump:user-messaging-platform:4.0.0")
    implementation("androidx.core:core:1.17.0")
}
