Class {
	#name : #DataStreamsRESTfulWebService,
	#superclass : #RESTfulWebService,
	#instVars : [
		'cosmos'
	],
	#category : #'Cosmos-API-Data'
}

{ #category : #'instance creation' }
DataStreamsRESTfulWebService class >> workingWith: aCosmosSystem [
	
	^ self new initializeWorkingWith: aCosmosSystem
]

{ #category : #API }
DataStreamsRESTfulWebService >> createStreamBasedOn: anHttpRequest within: aContext [

	^ [ self
		withCreatedResourceDo: [ :dataStream | self dataManagementSystem register: dataStream ]
		decodedUsing: self dataStreamsKey
		basedOn: anHttpRequest
		within: aContext ]
		on: InstanceCreationFailed
		do: [ :signal | HTTPClientError signalBadRequest: signal messageText ]
]

{ #category : #'private - systems' }
DataStreamsRESTfulWebService >> dataManagementSystem [

	^ cosmos systemImplementing: #DataManagementSystemInterface
]

{ #category : #'private - object types' }
DataStreamsRESTfulWebService >> dataStreamsKey [

	^ #data_streams
]

{ #category : #API }
DataStreamsRESTfulWebService >> deleteStreamBasedOn: anHttpRequest within: aContext [

	^ [ 
	self dataManagementSystem
		withStreamIdentifiedBy: (anHttpRequest at: #identifier)
		do: [ :dataStream | self dataManagementSystem deregister: dataStream ].

	ZnResponse noContent ]
		on: ObjectNotFound
		do: [ :signal | HTTPClientError signalNotFound: signal messageText ]
]

{ #category : #API }
DataStreamsRESTfulWebService >> getPointsBasedOn: anHttpRequest within: aContext [

	^ self
		get: [ (self dataManagementSystem streamIdentifiedBy: (anHttpRequest at: #identifier)) dataPoints ]
		encodedUsing: #data_points
		basedOn: anHttpRequest
		within: aContext
]

{ #category : #API }
DataStreamsRESTfulWebService >> getStreamsBasedOn: anHttpRequest within: aContext [

	^ [ self
		get: [ | streamsToEncode |

			self
				withIdentifierProvidedIn: anHttpRequest
				do: [ :identifier | self dataManagementSystem withStreamIdentifiedBy: identifier do: [ :dataStream | streamsToEncode := dataStream ] ]
				ifNone: [ streamsToEncode := self dataManagementSystem streams ].

			aContext hold: (cosmos systemImplementing: #MetadataSystemInterface) under: #metadata_system.
			streamsToEncode ]
		encodedUsing: #data_streams
		basedOn: anHttpRequest
		within: aContext ]
		on: DataStreamIsEmpty
		do: [ :signal | signal resume: 'N/A' ]
]

{ #category : #'private - systems' }
DataStreamsRESTfulWebService >> identifierSystem [

	^ cosmos systemImplementing: #IdentifierSystemInterface
]

{ #category : #initialization }
DataStreamsRESTfulWebService >> initializeWorkingWith: aCosmosSystem [

	cosmos := aCosmosSystem
]

{ #category : #'private - API' }
DataStreamsRESTfulWebService >> locationOf: aDataStream [

	| baseUrl |

	baseUrl := baseUrlOptional
		withContentDo: [ :theBaseUrl | theBaseUrl ]
		ifUnused: [ '' asZnUrl ].

	^ '<1p>/<2p>'
		expandMacrosWith: baseUrl / 'data-stream' asZnUrl
		with: (self identifierSystem identifierOf: aDataStream)
]

{ #category : #specification }
DataStreamsRESTfulWebService >> specification [

	^ DataStreamsRESTfulWebServiceSpecification new
]

{ #category : #'private - API' }
DataStreamsRESTfulWebService >> withIdentifierProvidedIn: anHttpRequest do: aBlock ifNone: ifNoneBlock [

	| identifierProvided |

	identifierProvided := true.
	anHttpRequest at: #identifier ifAbsent: [ identifierProvided := false ].

	identifierProvided
		ifTrue: [ aBlock value: (anHttpRequest at: #identifier) ]
		ifFalse: ifNoneBlock
]