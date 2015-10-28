//
//  GameViewController.m
//  SceneKitTest
//
//  Created by Odie Edo-Osagie on 27/04/2015.
//  Copyright (c) 2015 Odie Edo-Osagie. All rights reserved.
//

#import "GameViewController.h"
#import "GameCharacter.h"
#import "GameScene.h"
#import <SpriteKit/SpriteKit.h>

BOOL shouldStop;

@implementation GameViewController{
    SCNNode *cameraNode;
    NSMutableArray *animations;
    SCNNode *node;
    //SCNScene *scene;
    GameScene *scene;
    GameCharacter *character;
    // 系统加载的点的数据
    NSMutableArray *pointData;
    
    SKScene *overlay;
//    SKSpriteNode *walkAnimButton;
//    SKSpriteNode *cameraButton;
//    SKSpriteNode *wrenchButton;
//    SKSpriteNode *characterButton;
    NSArray *characterPaths;
    int currentCharacter;
    
    SCNVector3 forwardDirectionVector;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // iVar setup
    SCNView *scnView = (SCNView *)self.view;
    animations = [NSMutableArray array];
    characterPaths = @[@"art.scnassets/Kakashi.dae", @"Shisui", @"Sasuke"];
    currentCharacter = 0;
    //数据
    //pointData = [self loadData];
    // Setup Game Scene
    scene = [[GameScene alloc] initWithView:scnView];
    [scene setupSkyboxWithName:@"sun1" andFileExtension:@"bmp"];
    scnView.backgroundColor = [UIColor darkGrayColor];
    [self setupCamera];
    
    // create and add a light to the scene
    [self setupPointLight];
    
    // create and add an ambient light to the scene
    [self setupAmbientLight];
    //绘制曲线
    [self drawLine];
    
    // Setup Floor
    [self setupFloor];
    
    // Setup view
    scnView.scene = scene;
    //scnView.showsStatistics = YES;
    scnView.delegate = self;
    
    // Setup HUD
    //[self setupHUD];
    
}

//加载数据
-(void) loadData{
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test3D.txt" ofType:@"csv"];
    NSString *contents = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *contentsArray = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSInteger idx;
    for (idx = 0; idx < contentsArray.count; idx++) {
        NSString* currentContent = [contentsArray objectAtIndex:idx];
        NSArray *elements = [currentContent componentsSeparatedByString:@"	"];
        
    };

}

-(void) drawLine{
    //绘制曲线
    SCNVector3 positions[] = {
        SCNVector3Make(4.3, 0.34, 0.19),
        SCNVector3Make(5, 4, 3)
    };
    int indices[] = {0, 1};
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions
                                                                              count:2];
    NSData *indexData = [NSData dataWithBytes:indices
                                       length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:1
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *line = [SCNGeometry geometryWithSources:@[vertexSource]
                                                elements:@[element]];
    line.firstMaterial.diffuse.contents =  [UIColor redColor];
    SCNNode *lineNode = [SCNNode nodeWithGeometry:line];
    [scene.rootNode addChildNode:lineNode];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Setup Helpers

- (void) setupCharacter
{
    // Create Character and add to scene
    character = [[GameCharacter alloc] initFromScene:[SCNScene sceneNamed:@"art.scnassets/Kakashi.dae"] withName:@"SpongeBob"];
    //character = [[GameCharacter alloc] initFromScene:[SCNScene sceneNamed:@"Shisui.dae"] withName:@""];
    character.environmentScene = scene;
    [scene.rootNode addChildNode:character.characterNode];
    
    // Get Walk Animations
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"art.scnassets/Kakashi(walking)" withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:url options:@{SCNSceneSourceAnimationImportPolicyKey:SCNSceneSourceAnimationImportPolicyPlayRepeatedly} ];
    NSArray *animationIds = [sceneSource identifiersOfEntriesWithClass:[CAAnimation class]];
    for(NSString *eachId in animationIds){
        CAAnimation *animation = [sceneSource entryWithIdentifier:eachId withClass:[CAAnimation class]];
        [animations addObject:animation];
    }
    character.walkAnimations = [NSArray arrayWithArray:animations];
    
    
    // Get Idle Animations
    animations = [NSMutableArray array];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"art.scnassets/Kakashi(idle)" withExtension:@"dae"];
    SCNSceneSource *sceneSource2 = [SCNSceneSource sceneSourceWithURL:url2 options:@{SCNSceneSourceAnimationImportPolicyKey:SCNSceneSourceAnimationImportPolicyPlayRepeatedly} ];
    NSArray *animationIds2 = [sceneSource2 identifiersOfEntriesWithClass:[CAAnimation class]];
    for(NSString *eachId in animationIds2){
        CAAnimation *animation = [sceneSource2 entryWithIdentifier:eachId withClass:[CAAnimation class]];
        [animations addObject:animation];
    }
    character.idleAnimations = [NSArray arrayWithArray:animations];
    
    // Reset character to idle pose (rather than T-pose)
    character.actionState = ActionStateIdle;
}

- (void) setupFloor
{
    SCNFloor *floor = [SCNFloor new];
    floor.reflectivity = 0.0;
    
    SCNNode *floorNode = [SCNNode new];
    floorNode.geometry = floor;
    
    SCNMaterial *floorMaterial = [SCNMaterial new];
    floorMaterial.litPerPixel = NO;
    floorMaterial.diffuse.contents = [UIImage imageNamed:@"art.scnassets/grass.jpg"];
    floorMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    floorMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    
    floor.materials = @[floorMaterial];
    
    [scene.rootNode addChildNode:floorNode];
    
}

- (void) setupCamera
{
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.camera.zFar = 1000;
    cameraNode.position = SCNVector3Make(5, 6, 15);
    //设置相机的lookat点，目前设置为(0,0,0)点，假设以后人物角色站在这个位置上面挥杆
    [scene.rootNode addChildNode:cameraNode];
}

- (void) setupPointLight
{
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 200, -100);
    [scene.rootNode addChildNode:lightNode];
}

- (void) setupAmbientLight
{
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
}




#pragma mark - Tap Selectors

- (void) tap
{
    
}


- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
   // CGPoint p = [gestureRecognize locationInView:scnView];
   // NSArray *hitResults = [scnView hitTest:p options:nil];
}


#pragma mark - SCNRenderer Delegate

- (void)renderer:(id<SCNSceneRenderer>)aRenderer
    updateAtTime:(NSTimeInterval)time
{
}


#pragma mark - Touch Delegate

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //UITouch *touch = [touches anyObject];
    //CGPoint location = [touch locationInNode:overlay];
    //SKNode *touchedNode = [overlay nodeAtPoint:location];
    
}


#pragma mark - Orientation and Status Bar

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if(size.width > size.height){
            // Landscape
        }
        else{
            // Portrait
        }
        
        [overlay removeAllChildren];
    }];
    
}


#pragma mark - Vector Maths Helpers

+ (SCNVector3) rotateVector3:(SCNVector3)vector aroundAxis:(NSUInteger)axis byAngleInRadians:(float)angle
{
    if(axis == 1){
        SCNVector3 result = SCNVector3Make(cosf(angle)*vector.x+sinf(angle)*vector.z, vector.y, -sinf(angle)*vector.x+cosf(angle)*vector.z);
        return result;
    }
    else{
        return SCNVector3Zero;
    }
}




@end
