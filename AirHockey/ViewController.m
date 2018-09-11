//
//  ViewController.m
//  AirHockey
//
//  Created by Dan Jiang on 2018/8/28.
//  Copyright © 2018年 Dan Jiang. All rights reserved.
//

#import "ViewController.h"

typedef struct {
    float Position[2];
    float Color[3];
} Vertex;

static GLfloat const Vertices[70] = {
    // Triangle Fan
    0.0f,    0.0f, 0.0f, 1.5f,   1.0f,   1.0f,   1.0f,
    -0.5f, -0.8f, 0.0f,   1.0f, 0.7f, 0.7f, 0.7f,
    0.5f, -0.8f, 0.0f,   1.0f, 0.7f, 0.7f, 0.7f,
    0.5f,  0.8f, 0.0f,   2.0f, 0.7f, 0.7f, 0.7f,
    -0.5f,  0.8f, 0.0f,   2.0f, 0.7f, 0.7f, 0.7f,
    -0.5f, -0.8f, 0.0f,   1.0f, 0.7f, 0.7f, 0.7f,
    
    // Line 1
    -0.5f, 0.0f, 0.0f, 1.5f, 1.0f, 0.0f, 0.0f,
    0.5f, 0.0f, 0.0f, 1.5f, 1.0f, 0.0f, 0.0f,
    
    // Mallets
    0.0f, -0.4f, 0.0f, 1.25f, 0.0f, 0.0f, 1.0f,
    0.0f,  0.4f, 0.0f, 1.75f, 1.0f, 0.0f, 0.0f
};

@interface ViewController () <GLKViewControllerDelegate>
    
@property (strong, nonatomic) EAGLContext *context;
    
@property (assign, nonatomic, readonly) GLuint program;

@property (assign, nonatomic, readonly) GLuint uMatrix;

@property (assign, nonatomic, readonly) GLuint aPosition;
@property (assign, nonatomic, readonly) GLuint aColor;

@property (assign, nonatomic, readonly) GLKMatrix4 modelMatrix;
@property (assign, nonatomic, readonly) GLKMatrix4 projectionMatrix;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupGL];
}

- (void)setupGL {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *glkView = (GLKView *)self.view;
    glkView.context = self.context;
    self.delegate = self;
    
    EAGLContext.currentContext = self.context;

    glClearColor(0.0, 0.0, 0.0, 0.0);

    _program = [self programWithVertexShader:@"simple_vertex_shader" fragmentShader:@"simple_fragment_shader"];
    
    _uMatrix = glGetUniformLocation(_program, "u_Matrix");
    
    _aPosition = glGetAttribLocation(_program, "a_Position");
    _aColor = glGetAttribLocation(_program, "a_Color");

    glUseProgram(_program);
    
    glEnableVertexAttribArray(_aPosition);
    glEnableVertexAttribArray(_aColor);
    
    GLsizei stride = sizeof(GLfloat) * 7;

    glVertexAttribPointer(_aPosition, 4, GL_FLOAT, GL_FALSE, stride, Vertices);
    glVertexAttribPointer(_aColor, 3, GL_FLOAT, GL_FALSE, stride, &Vertices[4]);
}
    
- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    CGFloat height = UIScreen.mainScreen.bounds.size.height;

//    CGFloat aspectRatio = width > height ? width / height : height / width;
//
//    if (width > height) {
//        _projectionMatrix = GLKMatrix4MakeOrtho(-aspectRatio, aspectRatio, -1, 1, -1, 1);
//    } else {
//        _projectionMatrix = GLKMatrix4MakeOrtho(-1, 1, -aspectRatio, aspectRatio, -1, 1);
//    }
    
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), width / height, 1, 10);
    _modelMatrix = GLKMatrix4Identity;
    _modelMatrix = GLKMatrix4Translate(_modelMatrix, 0, 0, -2.5);
    _modelMatrix = GLKMatrix4Rotate(_modelMatrix, GLKMathDegreesToRadians(-60), 1, 0, 0);
    _projectionMatrix = GLKMatrix4Multiply(_projectionMatrix, _modelMatrix);
}
    
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUniformMatrix4fv(_uMatrix, 1, false, _projectionMatrix.m);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 6);
    glDrawArrays(GL_LINES, 6, 2);
    glDrawArrays(GL_POINTS, 8, 1);
    glDrawArrays(GL_POINTS, 9, 1);
}

- (GLuint)programWithVertexShader:(NSString*)vsh fragmentShader:(NSString*)fsh {
    // Build shaders
    GLuint vertexShader = [self shaderWithName:vsh type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self shaderWithName:fsh type:GL_FRAGMENT_SHADER];
    
    // Create program
    GLuint programHandle = glCreateProgram();
    
    // Attach shaders
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    
    // Link program
    glLinkProgram(programHandle);
    
    // Check for errors
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[1024];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSLog(@"%@:- GLSL Program Error: %s", [self class], messages);
    }
    
    // Delete shaders
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return programHandle;
}

- (GLuint)shaderWithName:(NSString*)name type:(GLenum)type {
    // Load the shader file
    NSString* file;
    if (type == GL_VERTEX_SHADER) {
        file = [[NSBundle mainBundle] pathForResource:name ofType:@"vsh"];
    } else if (type == GL_FRAGMENT_SHADER) {
        file = [[NSBundle mainBundle] pathForResource:name ofType:@"fsh"];
    }
    
    // Create the shader source
    const GLchar* source = (GLchar*)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    // Create the shader object
    GLuint shaderHandle = glCreateShader(type);
    
    // Load the shader source
    glShaderSource(shaderHandle, 1, &source, 0);
    
    // Compile the shader
    glCompileShader(shaderHandle);
    
    // Check for errors
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[1024];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSLog(@"%@:- GLSL Shader Error: %s", [self class], messages);
    }
    
    return shaderHandle;
}

@end
