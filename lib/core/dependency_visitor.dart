import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/utils.dart';

class DependencyVisitor {
  static const _relativeImportsConst = 'relative-imports';
  static const _absoluteImportsConst = 'absolute-imports';

  /// Regex for class name
  final classNameRegex = RegExp(r"(?:mixin|abstract class|class)\s+(\w+)");

  /// Regex for `extends`, `implements` & `with`
  final extendsRegex = RegExp(r"extends\s+(\w+)");
  final implementsRegex = RegExp(r"implements\s+([\w\s,]+)");
  final withRegex = RegExp(r"with\s+([\w\s,]+)");

  /// Regex for parsing import statements
  final importRegex = RegExp(r'''import\s+(?!'package:)(?:'|")(.*?)('|");?''');
  final packageImportRegex = RegExp(
    'import\\s+\'package:${Utils.appPackageName}(.*)\';',
  );

  final Map<String, bool> _visitorMap = {};

  String _dirName = '';

  bool _hasNotVisited(String filePath) {
    return _visitorMap[filePath] == null;
  }

  void _markVisited(String filePath) {
    _visitorMap[filePath] = true;
  }

  void reset() {
    _dirName = '';
    _visitorMap.clear();
  }

  /// Method which returns back the dependant's paths of a class file
  Set<String> getDependenciesPath(String filePath) {
    _dirName = path.dirname(filePath);
    final paths = _getDependenciesPath(filePath);
    reset();
    return paths;
  }

  Set<String> _getDependenciesPath(String filePath) {
    final dependencies = <String>{};
    final contents = File(filePath).readAsStringSync();

    final classDependencies = _getClassDependency(contents);
    final dependencyPaths = _resolveUri(contents, classDependencies);

    dependencies.addAll(dependencyPaths);

    /// Find out transitive dependencies
    for (final dependencyPath in dependencyPaths) {
      /// There can be a cyclic dependency, so to make sure we are not visiting the same node multiple times
      if (_hasNotVisited(dependencyPath)) {
        _markVisited(dependencyPath);
        final transitiveDependencies = _getDependenciesPath(dependencyPath);
        dependencies.addAll(transitiveDependencies);
      }
    }

    return dependencies;
  }

  Map<String, List<String>> _getImportLines(String dartSource) {
    final relativeImports = <String>[];
    final absoluteImports = <String>[];

    final lines = dartSource.split('\n');

    for (final line in lines) {
      final relativeMatch = importRegex.firstMatch(line);
      final packageMatch = packageImportRegex.firstMatch(line);

      if (relativeMatch != null) {
        final importedPath = relativeMatch.group(1);
        if (importedPath != null) relativeImports.add(importedPath);
      } else if (packageMatch != null) {
        final importedPath = packageMatch.group(1);
        if (importedPath != null) absoluteImports.add(importedPath);
      }
    }

    return {
      _relativeImportsConst: relativeImports,
      _absoluteImportsConst: absoluteImports,
    };
  }

  List<String> _convertImportStatementsToAbsolutePaths(String contents) {
    final importLines = _getImportLines(contents);
    final relativeImportLines = importLines[_relativeImportsConst] ?? const [];
    final absoluteImportLines = importLines[_absoluteImportsConst] ?? const [];

    final paths = <String>[];

    /// absolute import lines
    for (final import in absoluteImportLines) {
      paths.add(path.join(Utils.projectDirectory, 'lib', import.substring(1)));
    }

    /// relative import lines
    for (final import in relativeImportLines) {
      paths.add(path.normalize(path.join(_dirName, import)));
    }

    return paths;
  }

  Set<String> _resolveUri(String contents, Set<String> dependencies) {
    final importPaths = _convertImportStatementsToAbsolutePaths(contents);
    final paths = <String>{};

    for (final dependencyPath in importPaths) {
      final dependencyContents = File(dependencyPath).readAsStringSync();

      for (final dependencyClass in dependencies) {
        final classNameMatch = classNameRegex.firstMatch(dependencyContents);
        final className = classNameMatch?.group(1);
        if (className == dependencyClass) {
          paths.add(dependencyPath);
        }
      }
    }

    return paths;
  }

  Set<String> _getClassDependency(String contents) {
    final dependencies = <String>{};

    /// find matches
    final extendsMatch = extendsRegex.firstMatch(contents);
    final implementsMatch = implementsRegex.firstMatch(contents);
    final withMatch = withRegex.firstMatch(contents);

    if (extendsMatch != null) {
      dependencies.add(extendsMatch.group(1) ?? '');
    }

    if (implementsMatch != null) {
      final interfaces = implementsMatch.group(1)?.split(',') ?? const [];
      dependencies.addAll(interfaces.map((i) => i.trim()));
    }

    if (withMatch != null) {
      final mixins = withMatch.group(1)?.split(',') ?? const [];
      dependencies.addAll(mixins.map((m) => m.trim()));
    }

    return dependencies;
  }
}
