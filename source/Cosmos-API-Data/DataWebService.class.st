Class {
	#name : #DataWebService,
	#superclass : #Object,
	#instVars : [
		'cosmos',
		'mappingRuleSet'
	],
	#category : #'Cosmos-API-Data'
}

{ #category : #'instance creation' }
DataWebService class >> workingWith: aCosmosSystem [
	
	^ self new initializeWorkingWith: aCosmosSystem
]

{ #category : #API }
DataWebService >> createBulkPointsBasedOn: anHttpRequest within: aContext [

	^ [ | rawData |

	aContext hold: self currentDateTime under: #request_timestamp.

	rawData := self
		decode: anHttpRequest contents
		encodedAs: anHttpRequest contentType
		to: self dataPointsKey
		within: aContext.
		
	rawData
		do: [ :rawDataPoint | 
			self dataManagementSystem
				register: rawDataPoint value
				toStreamNamed: rawDataPoint key ].

	ZnResponse created: 'multiple' ]
		on: ObjectNotFound 
		do: [ :signal | 
			HTTPClientError
				signalBadRequest: signal messageText ]
]

{ #category : #API }
DataWebService >> createStreamBasedOn: anHttpRequest within: aContext [

	^ [ [ [ | dataStream dataStreamLocation |

	dataStream := self
		decode: anHttpRequest contents
		encodedAs: anHttpRequest contentType
		to: self dataStreamsKey
		within: aContext.

	self dataManagementSystem register: dataStream.

	dataStreamLocation := self locationOf: dataStream.

	ZnResponse created: dataStreamLocation ]
		on: ConflictingObjectFound
		do: [ :signal | HTTPClientError signalConflict: signal messageText ] ]
		on: KeyNotFound , InstanceCreationFailed
		do: [ :signal | HTTPClientError signalBadRequest: signal messageText ] ]
		on: MappingNotFound
		do:
			[ :signal | HTTPClientError signalUnsupportedMediaType: signal messageText ]
]

{ #category : #'private - accessing' }
DataWebService >> currentDateTime [

	^ self timeSystem dateTime
]

{ #category : #'private - systems' }
DataWebService >> dataManagementSystem [

	^ cosmos systemImplementing: #DataManagementSystemInterface
]

{ #category : #'private - object types' }
DataWebService >> dataPointsKey [

	^ #data_points
]

{ #category : #'private - object types' }
DataWebService >> dataStreamsKey [

	^ #data_streams
]

{ #category : #'private - deconding and encoding' }
DataWebService >> decode: aJSON encodedAs: aMediaType to: aKeyRepresentingObjectType within: aContext [

	^ (mappingRuleSet ruleToDecode: aMediaType to: aKeyRepresentingObjectType)
		applyOn: aJSON
		within: aContext
]

{ #category : #API }
DataWebService >> deleteStreamBasedOn: anHttpRequest within: aContext [

	^ [ 
	self dataManagementSystem
		withStreamIdentifiedBy: (anHttpRequest at: #identifier)
		do: [ :dataStream | self dataManagementSystem deregister: dataStream ].

	ZnResponse noContent ]
		on: ObjectNotFound
		do: [ :signal | HTTPClientError signalNotFound: signal messageText ]
]

{ #category : #'private - deconding and encoding' }
DataWebService >> encode: anObject of: aKeyRepresentingObjectType to: aMediaType within: aContext [

	^ (mappingRuleSet ruleToEncode: aKeyRepresentingObjectType to: aMediaType)
		applyOn: anObject
		within: aContext
]

{ #category : #API }
DataWebService >> getPointsBasedOn: anHttpRequest within: aContext [

	^ [ [ | mediaType encodedPoints |

	mediaType := self mediaTypeOf: anHttpRequest.

	self dataManagementSystem
		withStreamIdentifiedBy: (anHttpRequest at: #identifier)
		do: [ :dataStream | 
			encodedPoints := self
				encode: dataStream dataPoints
				of: #data_points
				to: mediaType
				within: aContext ].

	ZnResponse ok: (ZnEntity json: encodedPoints) ]
		on: TeaNoSuchParam
		do: [ :signal | HTTPClientError signalBadRequest: signal messageText ] ]
		on: ObjectNotFound
		do: [ :signal | HTTPClientError signalNotFound: signal messageText ]
]

{ #category : #API }
DataWebService >> getStreamsBasedOn: anHttpRequest within: aContext [

	^ [ [ [ | mediaType streamsToEncode encodedStreams |

	mediaType := self mediaTypeOf: anHttpRequest.

	self
		withIdentifierProvidedIn: anHttpRequest
		do: [ :identifier | 
			self dataManagementSystem
				withStreamIdentifiedBy: identifier
				do: [ :dataStream | streamsToEncode := dataStream ] ]
		ifNone: [ streamsToEncode := self dataManagementSystem streams ].

	aContext
		hold: (cosmos systemImplementing: #MetadataSystemInterface)
		under: #metadata_system.

	encodedStreams := self
		encode: streamsToEncode
		of: #data_streams
		to: mediaType
		within: aContext.

	ZnResponse ok: (ZnEntity json: encodedStreams) ]
		on: TeaNoSuchParam
		do: [ :signal | HTTPClientError signalBadRequest: signal messageText ] ]
		on: ObjectNotFound
		do: [ :signal | HTTPClientError signalNotFound: signal messageText ] ]
		on: DataStreamIsEmpty
		do: [ :signal | signal resume: 'N/A' ]
]

{ #category : #'private - systems' }
DataWebService >> identifierSystem [

	^ cosmos systemImplementing: #IdentifierSystemInterface
]

{ #category : #initialization }
DataWebService >> initializeWorkingWith: aCosmosSystem [

	cosmos := aCosmosSystem.
	mappingRuleSet := (ReflectiveMappingRuleSetBuilder
		for: self specification) build
]

{ #category : #'private - API' }
DataWebService >> locationOf: aDataStream [

	^ ZnUrl
		fromString:
			('localhost/<1s>'
				expandMacrosWith: (self identifierSystem identifierOf: aDataStream) asString36)
]

{ #category : #'private - API' }
DataWebService >> mediaTypeOf: anHttpRequest [

	^ ZnMimeType fromString: anHttpRequest accept
]

{ #category : #specification }
DataWebService >> specification [

	^ DataWebServiceSpecification new
]

{ #category : #'private - systems' }
DataWebService >> timeSystem [
	
	^ cosmos systemImplementing: #TimeSystemInterface
]

{ #category : #'private - API' }
DataWebService >> withIdentifierProvidedIn: anHttpRequest do: aBlock ifNone: ifNoneBlock [

	| identifierProvided |

	identifierProvided := true.
	anHttpRequest at: #identifier ifAbsent: [ identifierProvided := false ].

	identifierProvided
		ifTrue: [ aBlock value: (anHttpRequest at: #identifier) ]
		ifFalse: ifNoneBlock
]