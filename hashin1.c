#include<stdio.h>
#include<stdlib.h>
#define EMPTY -1
#define SIZE 10

int linear[SIZE];
int quadratic[SIZE];

struct Node{
        int key;
        struct Node* next;
};

struct Node* hashtable[SIZE];


void init(){
        for(int i=0;i<SIZE;i++){
                linear[i]=EMPTY;
                quadratic[i]=EMPTY;
        }
}

int hash(int key){
        return key%SIZE;
}

void insertchain(int key){
        int index=hash(key);
        struct Node* newNode=(struct Node*)malloc(sizeof(struct Node));
        newNode->key=key;
        newNode->next=hashtable[index];
        hashtable[index]=newNode;
}

int search_chain(int key){
        int index=hash(key);
        struct Node* temp=hashtable[index];
        int i=1;
        while(temp!=NULL){
                if(temp->key==key) return i;
                temp=temp->next;
                i++;
        }
        return -1;
}
int insertlinear(int key){
        int index=hash(key);
        int i=1;
        while(i<=SIZE){
                int newIndex=(index+(i-1))%SIZE;
                if(linear[newIndex]==EMPTY){
                        linear[newIndex]=key;
                        return i;
                }
                i++;
        }
        printf("No space in the hashtable\n");
}

int searchlinear(int key){
        int index=hash(key);
        int i=1;
        while(i<=SIZE){
                int newIndex=(index+(i-1))%SIZE;
                if(linear[newIndex]==EMPTY){
                        printf("No element found\n");
                        return -1;
                }
                else if(linear[newIndex]==key){
                        printf("Element found successfully\n");
                        return i;
                }
                i++;
        }
}

int insertquad(int key){
        int index=hash(key);
        int i=1;
        while(i<=SIZE){
                int newIndex=(index+(i-1)*(i-1))%SIZE;
                if(quadratic[newIndex]==EMPTY){
                        quadratic[newIndex]=key;
                        return i;
                }
                i++;
        }
        printf("No space in the hashtable\n");
}

int searchquad(int key){
        int index=hash(key);
        int i=1;
        while(i<=SIZE){
                int newIndex=(index+(i-1)*(i-1))%SIZE;
                if(quadratic[newIndex]==EMPTY){
                        printf("No element found\n");
                        return -1;
                }
                else if(quadratic[newIndex]==key){
                        printf("Element found successfully\n");
                        return i;
                }
                i++;
        }
}

void displaylin(){
    int i=0;
    while(i<SIZE){
        printf("%d-> %d\n",i,linear[i]);
        i++;
    }
}

void displayquad(){
    int i=0;
    while(i<SIZE){
        printf("%d-> %d\n",i,quadratic[i]);
        i++;
    }
}

int main(){
        init();
        int linearprobe=0;
        int quadprobe=0;
        int chain_probe=0;
        int *arr;
        int n;
        printf("Enter the size of array:");
        scanf("%d",&n);
        arr=(int*)malloc(n*sizeof(int));
        printf("Enter the elements of array:");
        for(int i=0;i<n;i++){
            scanf("%d",&arr[i]);
        }
        for(int i=0;i<n;i++){
            linearprobe+=insertlinear(arr[i]);
            quadprobe+=insertquad(arr[i]);
            insertchain(arr[i]);
        }

        displaylin();
        printf("\n");
        displayquad();
        printf("\n");
        printf("For inserting averageprobe:\n");
        printf("Average linearprobe:%d\n",linearprobe/n);
        printf("Average quadraticprobe:%d",quadprobe/n);
        printf("\n");
        int i=searchquad(32);
        printf("%d",i);

}