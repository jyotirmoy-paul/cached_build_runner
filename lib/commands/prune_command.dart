import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/args/argument_parser.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import 'package:cached_build_runner/di_container.dart';

class PruneCommand extends Command<void> {
  late final ArgumentParser _argumentParser;
  final Initializer _initializer;

  @override
  String get description => 'Prune cache directory';

  @override
  String get name => ArgsUtils.prune;

  @override
  bool get takesArguments => false;

  PruneCommand() : _initializer = const Initializer() {
    _argumentParser = ArgumentParser(argParser);
  }

  @override
  Future<void> run() {
    DiContainer.setup();

    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    final cachedBuildRunner = _initializer.init();

    return cachedBuildRunner.prune();
  }
}