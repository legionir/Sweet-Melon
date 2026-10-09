declare global {
  interface Window {
    NativeSDK: {
      waitForReady(timeoutMs?: number): Promise<any>;
      info(): {
        initialized: boolean;
        pendingRequests: number;
        totalRequests: number;
        version: string | null;
      };

      call(plugin: string, method: string, args?: any, extra?: any): Promise<any>;
      batch(requests: any[], options?: any): Promise<any[]>;
      on(event: string, callback: (data: any) => void): () => void;
      off(event: string, callback: (data: any) => void): void;

      permission: {
        check(permission: string): Promise<any>;
        request(permission: string): Promise<any>;
        checkMany(permissions: string[]): Promise<any>;
        requestMany(permissions: string[]): Promise<any>;
        openSettings(): Promise<any>;
        getKnownPermissions(): Promise<any>;
      };

      appLifecycle: {
        getState(): Promise<any>;
        enableEvents(): Promise<any>;
        disableEvents(): Promise<any>;
        getInfo(): Promise<any>;
      };

      deviceInfo: {
        getDeviceInfo(): Promise<any>;
        getAppInfo(): Promise<any>;
        getAll(): Promise<any>;
      };

      connectivity: {
        getStatus(): Promise<any>;
        isOnline(): Promise<any>;
        startWatch(): Promise<any>;
        stopWatch(): Promise<any>;
        getInfo(): Promise<any>;
      };

      storage: {
        get(key: string): Promise<any>;
        set(key: string, value: any): Promise<any>;
        remove(key: string): Promise<any>;
        clear(): Promise<any>;
        keys(): Promise<any>;
        has(key: string): Promise<any>;
      };

      fileSystem: {
        getDirectories(): Promise<any>;
        readFile(path: string, baseDir?: string, encoding?: string): Promise<any>;
        writeFile(path: string, content: string, options?: any): Promise<any>;
        deleteFile(path: string, baseDir?: string): Promise<any>;
        fileExists(path: string, baseDir?: string): Promise<any>;
        listFiles(path?: string, options?: any): Promise<any>;
        createDirectory(path: string, options?: any): Promise<any>;
        deleteDirectory(path: string, options?: any): Promise<any>;
        stat(path: string, options?: any): Promise<any>;
      };

      http: {
        request(options: any): Promise<any>;
        get(url: string, options?: any): Promise<any>;
        post(url: string, body?: any, options?: any): Promise<any>;
        put(url: string, body?: any, options?: any): Promise<any>;
        patch(url: string, body?: any, options?: any): Promise<any>;
        delete(url: string, options?: any): Promise<any>;
        download(options: any): Promise<any>;
      };

      intent: {
        openUrl(url: string, mode?: string): Promise<any>;
        canOpenUrl(url: string): Promise<any>;
        getInitialLink(): Promise<any>;
        getLatestLink(): Promise<any>;
        startListening(): Promise<any>;
        stopListening(): Promise<any>;
      };

      clipboard: {
        readText(): Promise<any>;
        writeText(text: string): Promise<any>;
        hasText(): Promise<any>;
        clear(): Promise<any>;
      };

      share: {
        shareText(text: string, subject?: string): Promise<any>;
        shareFiles(paths: string[], text?: string, subject?: string): Promise<any>;
      };

      camera: {
        getInfo(): Promise<any>;
        takePhoto(options?: any): Promise<any>;
        pickFromGallery(options?: any): Promise<any>;
      };

      geolocation: {
        checkPermission(): Promise<any>;
        requestPermission(): Promise<any>;
        getCurrentPosition(options?: any): Promise<any>;
        watchPosition(options?: any): Promise<any>;
        clearWatch(): Promise<any>;
        isLocationEnabled(): Promise<any>;
      };
    };
  }
}

export {};
