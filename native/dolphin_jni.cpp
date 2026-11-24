// SPDX-License-Identifier: GPL-2.0-or-later

#include <jni.h>

extern "C"
JNIEXPORT jstring JNICALL
Java_com_dolphintool_app_MainActivity_nativeVersion(
    JNIEnv* env, jobject)
{
    return env->NewStringUTF(
        "Motor nativo ARM64 conectado correctamente"
    );
}
