"
I'm a data stream.

A data stream is a bi-directional communications channel that allows for the exchange of data between the platform and authorized devices, applications, and services. Each data stream represents a specific attribute, unit or type of information (a variable). Some data stream may be defined automatically by the product template at the time of feed creation. The data stream associated with a feed can be added and deleted after a device is created. When data is written to an unspecified data stream using the IoT API, the data stream will be created dynamically.

"
Class {
	#name : #DataStream,
	#superclass : #Object,
	#instVars : [
		'name',
		'currentValue',
		'lastUpdate',
		'dataPoints'
	],
	#category : #'Cosmos-Data'
}

{ #category : #'instance creation' }
DataStream class >> assertIsNotEmpty: aName [

	AssertionChecker
		enforce: [ aName notEmpty ]
		because: 'Data stream name must not be empty'
		raising: InstanceCreationFailed
]

{ #category : #'instance creation' }
DataStream class >> named: aName [

	self assertIsNotEmpty: aName.

	^ self new initializeNamed: aName
]

{ #category : #comparing }
DataStream >> = anObject [

	^ self == anObject
		or: [ self class = anObject class
				and: [ name = anObject name ] ]
]

{ #category : #'adding data points' }
DataStream >> add: aDatapoint [

	currentValue := Binding to: aDatapoint value.
	lastUpdate := Binding to: aDatapoint timestamp.

	^ dataPoints add: aDatapoint
]

{ #category : #accessing }
DataStream >> currentValue [

	^ currentValue content
]

{ #category : #accessing }
DataStream >> dataPoints [

	^ dataPoints copy reversed
]

{ #category : #comparing }
DataStream >> hash [

	^ name hash
]

{ #category : #initialization }
DataStream >> initializeNamed: aName [

	name := aName.

	currentValue := Binding
		undefinedExplainedBy: 'Current value has not been initialized'
		raising: DataStreamIsEmpty.
	lastUpdate := Binding
		undefinedExplainedBy: 'Last update date and time has not been initialized'
		raising: DataStreamIsEmpty.

	dataPoints := OrderedCollection new
]

{ #category : #accessing }
DataStream >> lastUpdate [

	^ lastUpdate content
]

{ #category : #accessing }
DataStream >> name [

	^ name
]
