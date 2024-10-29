/* functions that convert from libvanilla to dart
  Copyright (C) 2024 unsimp

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */



import 'dart:ffi';
import 'dart:io';

import 'package:vanillaDart/vanilla_ffigen.dart';

class VanillaIsolate{
  late final VanillaDartBindings _bindings;


  // loads the library on instantiation
  VanillaIsolate(){

    final DynamicLibrary dylib = () {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open('vanilla.framework/vanilla');
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('libvanilla.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('vanilla.dll');
      }
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }();
    /// The bindings to the native functions in [_dylib].
    _bindings = VanillaDartBindings(dylib);







  }



}