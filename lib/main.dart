import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_gl/flutter_web_gl.dart';

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<int> textureId = init();
  late FlutterGLTexture texture;
  late RenderingContext gl;
  late Program program;

  Future<int> init() async {
    await FlutterWebGL.initOpenGL(true);
    texture = await FlutterWebGL.createTexture(1024, 768);
    gl = FlutterWebGL.getWebGLContext();

    gl.viewport(0, 0, 1024, 768);
    gl.clearColor(0, 0, 0, 1);

    final vShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vShader, '''
attribute vec2 pos;

void main() {
  gl_Position = vec4(pos, 1, 1);
}
''');

    gl.compileShader(vShader);

    final fShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fShader, '''
void main() {
  gl_FragColor = vec4(1, 0, 0, 1);
}
''');

    gl.compileShader(fShader);

    program = gl.createProgram();
    gl.attachShader(program, vShader);
    gl.attachShader(program, fShader);

    gl.linkProgram(program);
    gl.useProgram(program);

    texture.activate();

    return texture.textureId;
  }

  draw() {
    gl.clear(WebGL.COLOR_BUFFER_BIT);

    final vBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vBuffer);

    final bufferData = Float32List.fromList([
      -1,
      -1,
      1,
      1,
      1,
      -1,
    ]);

    final posAttrLocation = gl.getAttribLocation(program, 'pos');

    gl.enableVertexAttribArray(posAttrLocation);
    gl.vertexAttribPointer(posAttrLocation, 2, WebGL.FLOAT, false, 0, 0);

    gl.bufferData(WebGL.ARRAY_BUFFER, bufferData, WebGL.STATIC_DRAW);
    gl.drawArrays(WebGL.TRIANGLES, 0, 6);

    texture.signalNewFrameAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FutureBuilder(
        future: textureId,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(
              children: [
                Texture(textureId: snapshot.data as int),
                OutlinedButton(
                  child: Text('Draw'),
                  onPressed: () {
                    draw();
                  },
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
