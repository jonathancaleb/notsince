import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// The NDK version the Flutter Gradle plugin pins plugins to. It is hardcoded in
// Flutter itself (FlutterExtension.kt), so packages like `jni` inherit it through
// `ndkVersion flutter.ndkVersion` and it cannot be changed from app/build.gradle.kts.
val flutterPinnedNdkVersion = "28.2.13676358"

// The NDK version actually installed in the local Android SDK.
val installedNdkVersion = "30.0.16248370"

// Resolves the Android SDK directory the same way AGP does.
fun androidSdkDir(): File? {
    val localProperties = rootProject.file("local.properties")
    val fromLocalProperties =
        if (localProperties.exists()) {
            val properties = java.util.Properties()
            localProperties.inputStream().use { properties.load(it) }
            properties.getProperty("sdk.dir")
        } else {
            null
        }
    val sdkPath =
        fromLocalProperties
            ?: System.getenv("ANDROID_HOME")
            ?: System.getenv("ANDROID_SDK_ROOT")
    return sdkPath?.let(::File)
}

// AGP aborts configuration with CXX1101 when a module's ndkVersion has no
// `source.properties`: Flutter pins plugins to 28.2.13676358 via
// `ndkVersion flutter.ndkVersion`, that version is not actually installed here (an
// interrupted download left the folder behind), and app/build.gradle.kts cannot
// change what a pub package asks for. Repoint those modules at an NDK that is
// genuinely present.
//
// The check mirrors Flutter's own "is this NDK installed" test (source.properties
// exists), so this stops applying as soon as the pinned NDK is installed for real.
//
// Registered before the `evaluationDependsOn(":app")` block below: once a project is
// evaluated, afterEvaluate can no longer be registered on it. Registering here also
// puts it ahead of AGP's own afterEvaluate block, which is what resolves the NDK.
subprojects {
    afterEvaluate {
        val androidExtension =
            extensions.findByName("android") as? BaseExtension ?: return@afterEvaluate
        if (androidExtension.ndkVersion != flutterPinnedNdkVersion) return@afterEvaluate

        val pinnedNdkSourceProperties =
            androidSdkDir()?.resolve("ndk/$flutterPinnedNdkVersion/source.properties")
        if (pinnedNdkSourceProperties?.isFile == true) return@afterEvaluate

        androidExtension.ndkVersion = installedNdkVersion
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
