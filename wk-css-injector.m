#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <unistd.h>

static void RiptideLog(NSString *message) {
  NSString *line = [NSString stringWithFormat:@"%@ pid=%d %@\n",
                    [NSDate date],
                    getpid(),
                    message];
  NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
  NSString *path = @"/tmp/riptide-rounded-injector.log";

  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    [data writeToFile:path atomically:YES];
    return;
  }

  NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
  [handle seekToEndOfFile];
  [handle writeData:data];
  [handle closeFile];
}

static NSString *RiptideJSONString(NSString *value) {
  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:@[value ?: @""]
                                                 options:0
                                                   error:&error];
  if (!data || error) {
    return @"\"\"";
  }

  NSString *arrayJSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (arrayJSON.length < 2) {
    return @"\"\"";
  }

  return [arrayJSON substringWithRange:NSMakeRange(1, arrayJSON.length - 2)];
}

static NSString *RiptidePresetName(void) {
  const char *presetEnv = getenv("RIPTIDE_THEME_PRESET");
  if (!presetEnv || presetEnv[0] == '\0') {
    return nil;
  }

  NSString *preset = [NSString stringWithUTF8String:presetEnv];
  NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
    @"abcdefghijklmnopqrstuvwxyz0123456789-"];
  if (!preset.length || [preset rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) {
    RiptideLog([NSString stringWithFormat:@"ignored invalid theme preset: %@", preset]);
    return nil;
  }

  return preset;
}

static NSString *RiptideInjectionScript(void) {
  const char *cssPathEnv = getenv("RIPTIDE_CUSTOM_CSS");
  if (!cssPathEnv || cssPathEnv[0] == '\0') {
    RiptideLog(@"RIPTIDE_CUSTOM_CSS was not set");
    return nil;
  }

  NSString *cssPath = [NSString stringWithUTF8String:cssPathEnv];
  NSError *error = nil;
  NSString *css = [NSString stringWithContentsOfFile:cssPath
                                            encoding:NSUTF8StringEncoding
                                               error:&error];
  if (!css || error) {
    RiptideLog([NSString stringWithFormat:@"failed to read CSS at %@", cssPath]);
    return nil;
  }

  NSString *preset = RiptidePresetName();
  if (preset.length) {
    NSString *presetPath = [[[cssPath stringByDeletingLastPathComponent]
      stringByAppendingPathComponent:@"presets"]
      stringByAppendingPathComponent:[preset stringByAppendingPathExtension:@"css"]];
    error = nil;
    NSString *presetCSS = [NSString stringWithContentsOfFile:presetPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:&error];
    if (!presetCSS || error) {
      RiptideLog([NSString stringWithFormat:@"failed to read theme preset at %@", presetPath]);
      preset = nil;
    } else {
      css = [css stringByAppendingFormat:@"\n\n%@", presetCSS];
      RiptideLog([NSString stringWithFormat:@"loaded theme preset %@", preset]);
    }
  }

  NSString *cssJSON = RiptideJSONString(css);
  NSString *presetJSON = RiptideJSONString(preset ?: @"");

  return [NSString stringWithFormat:
    @"(() => {"
      "const css = %@;"
      "const preset = %@;"
      "const cssId = 'riptide-rounded-local-css';"
      "function target() { return document.head || document.documentElement; }"
      "function install() {"
        "const parent = target();"
        "if (!parent) { setTimeout(install, 16); return; }"
        "if (preset) document.documentElement.dataset.rrPreset = preset;"
        "else delete document.documentElement.dataset.rrPreset;"
        "let style = document.getElementById(cssId);"
        "if (!style) {"
          "style = document.createElement('style');"
          "style.id = cssId;"
          "style.type = 'text/css';"
          "parent.appendChild(style);"
        "}"
        "if (style.textContent !== css) style.textContent = css;"
      "}"
      "install();"
      "document.addEventListener('DOMContentLoaded', install, { once: true });"
      "new MutationObserver(() => {"
        "if (!document.getElementById(cssId)) install();"
      "}).observe(document.documentElement || document, { childList: true, subtree: true });"
    "})();",
    cssJSON,
    presetJSON
  ];
}

static void RiptideAddUserScript(WKWebViewConfiguration *configuration) {
  if (!configuration) {
    return;
  }

  NSString *scriptSource = RiptideInjectionScript();
  if (!scriptSource.length) {
    return;
  }

  WKUserContentController *controller = configuration.userContentController;
  if (!controller) {
    controller = [[WKUserContentController alloc] init];
    configuration.userContentController = controller;
  }

  WKUserScript *script = [[WKUserScript alloc] initWithSource:scriptSource
                                                injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                             forMainFrameOnly:YES];
  [controller addUserScript:script];
  RiptideLog(@"added WKUserScript for rounded CSS and selected preset");
}

typedef id (*RiptideInitWithFrameConfigurationIMP)(id self, SEL _cmd, CGRect frame, WKWebViewConfiguration *configuration);
static RiptideInitWithFrameConfigurationIMP RiptideOriginalInitWithFrameConfiguration = NULL;

static id RiptideInitWithFrameConfiguration(id self, SEL _cmd, CGRect frame, WKWebViewConfiguration *configuration) {
  RiptideAddUserScript(configuration);
  return RiptideOriginalInitWithFrameConfiguration(self, _cmd, frame, configuration);
}

__attribute__((constructor))
static void RiptideInstallWKWebViewHook(void) {
  RiptideLog(@"loaded local CSS injector dylib");

  Class webViewClass = objc_getClass("WKWebView");
  SEL selector = @selector(initWithFrame:configuration:);
  Method method = class_getInstanceMethod(webViewClass, selector);
  if (!method) {
    RiptideLog(@"WKWebView initWithFrame:configuration: was not found");
    return;
  }

  RiptideOriginalInitWithFrameConfiguration = (RiptideInitWithFrameConfigurationIMP)method_getImplementation(method);
  method_setImplementation(method, (IMP)RiptideInitWithFrameConfiguration);
}
