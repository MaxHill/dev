/* Check the palette loaded through GTK's real user stylesheet entry point. */
#include <gtk/gtk.h>
#include <math.h>
#ifdef WITH_ADWAITA
#include <adwaita.h>
#endif

int main(int argc, char **argv) {
#if GTK_MAJOR_VERSION >= 4
    gtk_init();
#ifdef WITH_ADWAITA
    adw_init();
    GtkWidget *window = adw_window_new();
#else
    GtkWidget *window = gtk_window_new();
#endif
#else
    gtk_init(&argc, &argv);
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
#endif
    GdkRGBA actual, expected;
    if (argc != 2 || !gdk_rgba_parse(&expected, argv[1])) return 2;
    if (!gtk_style_context_lookup_color(gtk_widget_get_style_context(window),
                                        "window_bg_color", &actual)) return 3;
    char *value = gdk_rgba_to_string(&actual);
    g_print("Loaded window background: %s; expected %s\n", value, argv[1]);
    g_free(value);
    return fabs(actual.red - expected.red) > 0.001 ||
           fabs(actual.green - expected.green) > 0.001 ||
           fabs(actual.blue - expected.blue) > 0.001;
}
