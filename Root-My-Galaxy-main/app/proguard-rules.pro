# Compose 基础混淆规则
-keep class androidx.compose.** { *; }
-keepnames class androidx.compose.**
-keep class kotlinx.coroutines.** { *; }

# 保留你的业务代码，防止被误删
-keep class dev.busung.s25uroot.** { *; }

# 原生jni方法必须保留
-keepclasseswithmembernames class * {
    native <methods>;
}

# 关闭无用日志（可选，进一步瘦身）
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}
