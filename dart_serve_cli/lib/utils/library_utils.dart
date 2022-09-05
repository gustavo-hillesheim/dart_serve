class LibraryUtils {
  static String createRoutesLibraryName(String libraryIdentifier) {
    final libraryName = libraryIdentifier
        .substring(libraryIdentifier.indexOf('/') + 1)
        .split('.dart')[0];
    return '${libraryName}_routes';
  }

  static String getPackageName(String libraryIdentifier) {
    return libraryIdentifier.split('/')[0].split(':')[1];
  }
}
