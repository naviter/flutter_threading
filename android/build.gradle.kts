import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

val targetProjects = listOf(
    "background_locator_2",
    "flutter_isolate",
    "http_proxy",
    "system_proxy",
    "battery_info",
    "raw_sound"
)


subprojects {
    afterEvaluate {
        if (project.name in targetProjects) {
            if (project.plugins.hasPlugin("com.android.application") ||
                project.plugins.hasPlugin("com.android.library")
            ) {
                val androidExt = project.extensions.findByName("android")
                if (androidExt is BaseExtension) {
                    androidExt.compileSdkVersion(31)
                    androidExt.buildToolsVersion("31.0.0")
                }
            }
        }
        if (project.extensions.findByName("android") != null) {
            val androidExt = project.extensions.findByName("android")

            // Only proceed if it's a BaseExtension (App/Library plugin)
            if (androidExt is com.android.build.gradle.BaseExtension) {
                if (androidExt.namespace.isNullOrEmpty()) {
                    androidExt.namespace = if (project.group.toString().isNotBlank()) {
                        project.group.toString()
                    } else {
                        "com.temp.${project.name}"
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
