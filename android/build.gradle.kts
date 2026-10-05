allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Alte Plugins (z.B. image_gallery_saver, pedometer) setzen keinen Namespace,
// neuere AGP-Versionen verlangen einen: aus dem package-Attribut im Manifest übernehmen
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                val manifest = file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    Regex("package=\"([^\"]+)\"").find(manifest.readText())?.let {
                        namespace = it.groupValues[1]
                    }
                }
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
