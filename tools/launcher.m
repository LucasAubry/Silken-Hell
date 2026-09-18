#import <AppKit/AppKit.h>

// Launch the published local archive without rebuilding cloud files.
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *project = [NSBundle.mainBundle.bundlePath stringByDeletingLastPathComponent];
        NSString *script = [project stringByAppendingPathComponent:@"Lancer Silken Hell.command"];
        NSFileManager *fm = NSFileManager.defaultManager;
        if (![fm fileExistsAtPath:script]) {
            [NSApplication sharedApplication];
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Installation de Silken Hell manquante";
            alert.informativeText = @"Place ce bouton dans le dossier du projet, à côté de « Lancer Silken Hell.command ».";
            [alert addButtonWithTitle:@"OK"];
            [NSApp activateIgnoringOtherApps:YES];
            [alert runModal];
            return 1;
        }
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/bin/zsh"];
        task.arguments = @[script];
        NSError *error = nil;
        BOOL launched = [task launchAndReturnError:&error];
        if (launched) [task waitUntilExit];
        if (!launched || task.terminationStatus != 0) {
            [NSApplication sharedApplication];
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Impossible de lancer Silken Hell";
            alert.informativeText = error.localizedDescription ?: @"Le moteur LÖVE n’a pas pu démarrer.";
            [alert addButtonWithTitle:@"OK"];
            [NSApp activateIgnoringOtherApps:YES];
            [alert runModal];
            return 1;
        }
        return 0;
    }
}
