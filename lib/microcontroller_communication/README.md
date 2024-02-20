# Microcontroller Communication

This tries to simplify microcontrollers communication with wireless ports

## `Communication.SendMessage(topicName: string, port: (port number or object), dataToSend: any): MessageResult`
> - Requires disk on the provided port  
> - Send a message that subscribed microcontrollers can read from

___  
## `Communication.SubscribeToTopic(topicName: string, port: (port number or object), callbackFunction): TopicSubscription`
> Subscribes and runs the provided callback whenever a microcontroller sends the message (god im bad at writing this)

___
# Objects

## `Communication.MessageResult`
     .Results: (array/dict): Name of the topic the subscription is subscribed to  
     :WaitForResult(index: any, timeoutSeconds: number) Waits the amount of seconds for the index to be added to the .Results table.
___    
## `Communication.TopicSubscription`
        .TopicName: Name of the topic the subscription is subscribed to.
        
        :Unbind(): Unbinds the topic subscription from the callback.
        
        :SendReturnMessage(topicName: string, dataToSend: any)
            Sends a message using the disk of the latest sender. Can allow messages to be sent along the network without the specific
            microcontroller having a disk of it's own
