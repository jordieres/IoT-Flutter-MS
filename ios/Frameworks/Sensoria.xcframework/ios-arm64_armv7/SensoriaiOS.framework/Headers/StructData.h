//
//  StructData.h
//  SensoriaFramework
//
//  Created by Daniele on 22/03/17.
//  Copyright © 2017 Sensoria Inc. All rights reserved.
//

#ifndef StructData_h
#define StructData_h

#include <stdio.h>

typedef enum {
    FastStreamingProtocolA13,
    FastStreamingProtocolA20,
    FastStreamingProtocolB13,
    FastStreamingProtocolB20,
    FastStreamingProtocolC13,   // Reserved, not being used
    FastStreamingProtocolC20,
    FastStreamingProtocolD20,   // Not implemented ??
    FastStreamingProtocolE20,   // Not implemented ??
    FastStreamingProtocolF20,
    FastStreamingProtocolG20,
    FastStreamingProtocolH20,
    FastStreamingProtocolI20,
    FastStreamingProtocolJ20,
    FastStreamingProtocolUnknown
} FastStreamingProtocol;

typedef enum {
    DeviceTypeGeneric = 0,
    DeviceTypeHeartMonitor = 1,
    DeviceTypeAnklet = 2,			// OBSOLETED
    DeviceTypeCore = 3,
    DeviceTypeSamsungBalance = 4 	// OBSOLETED
} DeviceType;

// Note This enum needs to be synchronized with bitbucket::sensoria-signal-processing\Source\Algos\WalkRun\SignalProcessing.h enum type SignalProcessing::DeviceBodyLocation
typedef enum {
    DeviceBodyLocationNone = 0,
    DeviceBodyLocationSock = 1,
    DeviceBodyLocationSock20 = 2,
    DeviceBodyLocationSensoriaShoe = 3,
    DeviceBodyLocationVivoShoe = 4,
    DeviceBodyLocationInsole = 5,
    DeviceBodyLocationChest = 100,
    DeviceBodyLocationKneeAbove = 101,
    DeviceBodyLocationKneeBelow = 102
} DeviceBodyLocation;

// Note This enum needs to be synchronized with bitbucket::sensoria-signal-processing\Source\Algos\WalkRun\SignalProcessing.h enum type SignalProcessing::DeviceBodPosition
typedef enum {
    DeviceBodyPositionNone = 0,
    DeviceBodyPositionLeft = 1,
    DeviceBodyPositionRight = 2,
    DeviceBodyPositionMiddle = 3
    } DeviceBodyPosition;

//get (DeviceBodyLocation + DeviceBodyPosition)
typedef enum {
    DeviceLocationAndPositionNone = 0,
    DeviceLocationAndPositionFootLeft = 1,
    DeviceLocationAndPositionFootRight = 2,
    DeviceLocationAndPositionShoeLeft = 3,
    DeviceLocationAndPositionShoeRight = 4,
    DeviceLocationAndPositionKneeLeft = 5,
    DeviceLocationAndPositionKneeRight = 6,
    DeviceLocationAndPositionHeartMiddle = 7
} DeviceLocationAndPosition;

typedef struct {
    uint16_t s0;
    uint16_t s1;
    uint16_t s2;
    uint16_t s3;
    uint16_t s4;
    uint16_t s5;
    uint16_t s6;
    uint16_t s7;
    
    float accX;
    float accY;
    float accZ;
    float gyroX;
    float gyroY;
    float gyroZ;
    float magX;
    float magY;
    float magZ;
    
    float hrm;
    float yaw;
    float pitch;
    float roll;
    float rssi;
    
    double timestamp; //from 1/1/1970 00:00:00
    
    int tick;
    int samplingFrequency;
    
    FastStreamingProtocol deviceFastStreamingProtocol;
    DeviceType deviceType;
    DeviceBodyPosition deviceBodyPosition;
    DeviceBodyLocation deviceBodyLocation;
    
    //get (DeviceBodyLocation + DeviceBodyPosition)
    DeviceLocationAndPosition deviceLocationAndPosition;
    
} SAData;

#endif /* StructData_h */
