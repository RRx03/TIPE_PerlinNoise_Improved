
#include <metal_stdlib>
using namespace metal;

#define particleNumber 100
#define flowRate 1
#define frameRate (60*flowRate)
#define dt (1.0/frameRate)
#define pixelToMeter 6300


#define twoPI 3.1415*2
#define PI 3.1415




struct Uniform{
    float brightness;
    short time;
};




float random (float2 vec, float seed = 43758.5453123) {
    return fract(sin(dot(vec,float2(12.9898,78.233)))*seed);
//    return fract(sin(dot(vec,float2(12.9898,78.233)))*43758.5453123);
}

float2 randomVect(float2 normalizedPos, uint2 idPos){
    return  float2(random(float2(normalizedPos.x, idPos.y), random(float2(idPos), 43758.5453123)*43758.5453123), random(float2(normalizedPos.y, idPos.x), random(float2(idPos), 43758.5453123)*43758.5453123));
}

float noise(uint2 position, float2 scaleNumber, float2 inPositionNormalized){
    float2 gradientVectors[4];
    float2 distanceVectors[4];
    float influenceValues[4];
    for (int i = 0; i < 4; i++){
        uint2 relativeCoordinate = uint2(i%2, i*(i-1)*((-2*i+7)/6));
        uint2 newPosition = position+relativeCoordinate;
        float2 newNormalizedPosition = float2(newPosition)/(scaleNumber+1);
        float2 distanceVector = inPositionNormalized - float2(relativeCoordinate);

        float2 gradientVector = 2*randomVect(newNormalizedPosition, newPosition)-1;



        gradientVectors[i] = gradientVector;
        distanceVectors[i] = distanceVector;
        influenceValues[i] = (1+dot(gradientVector, distanceVector))/2;
        
    }
    float2 interpolator = float2(inPositionNormalized);
    float average = (1-interpolator.y)*(1-interpolator.x)*influenceValues[0]+(1-interpolator.y)*interpolator.x*influenceValues[1]+interpolator.y*(1-interpolator.x)*influenceValues[2]+interpolator.x*interpolator.y*influenceValues[3];
    
    
    
    return average;
    
    
    
}

kernel void pixels(texture2d<half, access::read> textureIn [[texture(1)]],
                   texture2d<half, access::write> textureOut [[texture(0)]],
                   constant Uniform &uniform [[buffer(1)]],
                   uint2 id [[thread_position_in_grid]]) {
    
    
    #define showVectors false
    
    float2 screenSize = float2(textureOut.get_width(), textureOut.get_height());
    float2 normalizedPos = float2(id)/screenSize;
    
    half3 pixelColor;
    
    float2 scaleSize = float2(100)*2;
    float2 scaleNumber = (screenSize/scaleSize)+1;
    uint2 gridPosition = uint2(floor(float2(id)/scaleSize));
    float2 inGridPositionNormalized = fract(float2(id)/scaleSize);
    float2 gridPositionNormalized = float2(gridPosition)/scaleNumber;

    float2 gradientVectors[4];
    float2 distanceVectors[4];
    float influenceValues[4];
    
    for (int i = 0; i < 4; i++){
        
        uint2 relativeCoordinate;
        
        switch (i){
            case 0 :{
                relativeCoordinate = uint2(0, 0);
            }
                break;
            case 1 :{
                relativeCoordinate = uint2(1, 0);
            }
                break;
            case 2 :{
                relativeCoordinate = uint2(0, 1);
                break;
            }
            case 3 :{
                relativeCoordinate = uint2(1, 1);
                break;
            }
                
        }
       
        
        uint2 newPosition = gridPosition+relativeCoordinate;
        float2 newNormalizedPosition = float2(newPosition)/scaleNumber;
        float2 distanceVector = inGridPositionNormalized - float2(relativeCoordinate);
        uint2 newPositionId = newPosition*uint2(scaleSize);
        float2 gradientVector = 2*randomVect(float2(newPositionId), newPositionId)-1;

        gradientVectors[i] = gradientVector;
        distanceVectors[i] = distanceVector;
        influenceValues[i] = (1+dot(gradientVector, distanceVector))/2;
        
        if (length(distanceVector) < 0.1 && showVectors){
            for(int j = 0; j < 10; j++){
                float2 newPosi = float2(newPositionId) + gradientVector*2*j;
                textureOut.write(half4(1, 0, 0, 1), uint2(newPosi));
                textureOut.write(half4(1, 0, 0, 1), uint2(newPosi)+uint2(1, 0));
                textureOut.write(half4(1, 0, 0, 1), uint2(newPosi)+uint2(0, 1));
                textureOut.write(half4(1, 0, 0, 1), uint2(newPosi)-uint2(1, 0));
                textureOut.write(half4(1, 0, 0, 1), uint2(newPosi)-uint2(0, 1));
                
            }
            
        }
        
    }
    float2 u =float2(inGridPositionNormalized);
    float2 interpolator = 6*pow(u, 5)-15*pow(u, 4)+10*pow(u, 3);
    float average = (1-interpolator.y)*(1-interpolator.x)*influenceValues[0]+(1-interpolator.y)*interpolator.x*influenceValues[1]+interpolator.y*(1-interpolator.x)*influenceValues[2]+interpolator.x*interpolator.y*influenceValues[3];
    



    pixelColor = half3(average);
    
    
    textureOut.write(half4(pixelColor*uniform.brightness, 1), id);

    
    
}


