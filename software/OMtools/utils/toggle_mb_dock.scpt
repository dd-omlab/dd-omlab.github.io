FasdUAS 1.101.10   ��   ��    k             l     ����  O       	  I   �� 
��
�� .miscmvisnull���     **** 
 5    	�� ��
�� 
xppb  m       �   8 c o m . a p p l e . p r e f e r e n c e . g e n e r a l
�� kfrmID  ��   	 m       �                                                                                  sprf  alis    P  Hard Guy VI                    BD ����System Preferences.app                                         ����            ����  
 cu             Applications  &/:Applications:System Preferences.app/  .  S y s t e m   P r e f e r e n c e s . a p p    H a r d   G u y   V I  #Applications/System Preferences.app   / ��  ��  ��        l    ����  I   �� ��
�� .sysodelanull��� ��� nmbr  m    ���� ��  ��  ��        l   2 ����  O   2    O   1    O     0    I  ' /�� ��
�� .prcsclicnull��� ��� uiel  4   ' +�� 
�� 
chbx  m   ) *   �   P A u t o m a t i c a l l y   h i d e   a n d   s h o w   t h e   m e n u   b a r��    4     $��  
�� 
cwin   m   " # ! ! � " "  G e n e r a l  4    �� #
�� 
prcs # m     $ $ � % % $ S y s t e m   P r e f e r e n c e s  m     & &�                                                                                  sevs  alis    Z  Hard Guy VI                    BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    H a r d   G u y   V I  -System/Library/CoreServices/System Events.app   / ��  ��  ��     ' ( ' l     ��������  ��  ��   (  ) * ) l  3 � +���� + O   3 � , - , O   7  . / . k   = ~ 0 0  1 2 1 l  = =�� 3 4��   3 g aget the properties list of the dock and set (or assign) it to our variable we'll call "dockprops"    4 � 5 5 � g e t   t h e   p r o p e r t i e s   l i s t   o f   t h e   d o c k   a n d   s e t   ( o r   a s s i g n )   i t   t o   o u r   v a r i a b l e   w e ' l l   c a l l   " d o c k p r o p s " 2  6 7 6 r   = E 8 9 8 e   = A : : 1   = A��
�� 
pALL 9 o      ���� 0 	dockprops   7  ; < ; l  F F�� = >��   = o iin our now "dockprops" list, assign our target dock property ("autohide") to the variable "dockhidestate"    > � ? ? � i n   o u r   n o w   " d o c k p r o p s "   l i s t ,   a s s i g n   o u r   t a r g e t   d o c k   p r o p e r t y   ( " a u t o h i d e " )   t o   t h e   v a r i a b l e   " d o c k h i d e s t a t e " <  @ A @ r   F Q B C B n   F M D E D 1   I M��
�� 
dahd E o   F I���� 0 	dockprops   C o      ���� 0 dockhidestate   A  F G F l  R R�� H I��   H ^ Xthe dock's "autohide" property is a boolean: it's value can only be either true or false    I � J J � t h e   d o c k ' s   " a u t o h i d e "   p r o p e r t y   i s   a   b o o l e a n :   i t ' s   v a l u e   c a n   o n l y   b e   e i t h e r   t r u e   o r   f a l s e G  K L K l  R R�� M N��   M x ran "if statement" provides the necessary logic to correctly handle either of these cases in this one single script    N � O O � a n   " i f   s t a t e m e n t "   p r o v i d e s   t h e   n e c e s s a r y   l o g i c   t o   c o r r e c t l y   h a n d l e   e i t h e r   o f   t h e s e   c a s e s   i n   t h i s   o n e   s i n g l e   s c r i p t L  P�� P Z   R ~ Q R�� S Q =   R Y T U T 1   R W��
�� 
dahd U m   W X��
�� boovtrue R O   \ t V W V O  ` s X Y X r   f r Z [ Z H   f l \ \ 1   f k��
�� 
dahd [ 1   l q��
�� 
dahd Y 1   ` c��
�� 
dpas W m   \ ] ] ]�                                                                                  sevs  alis    Z  Hard Guy VI                    BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    H a r d   G u y   V I  -System/Library/CoreServices/System Events.app   / ��  ��   S r   w ~ ^ _ ^ m   w x��
�� boovtrue _ 1   x }��
�� 
dahd��   / 1   7 :��
�� 
dpas - m   3 4 ` `�                                                                                  sevs  alis    Z  Hard Guy VI                    BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    H a r d   G u y   V I  -System/Library/CoreServices/System Events.app   / ��  ��  ��   *  a�� a l  � � b���� b I  � ��� c��
�� .aevtquitnull��� ��� null c m   � � d d�                                                                                  sprf  alis    P  Hard Guy VI                    BD ����System Preferences.app                                         ����            ����  
 cu             Applications  &/:Applications:System Preferences.app/  .  S y s t e m   P r e f e r e n c e s . a p p    H a r d   G u y   V I  #Applications/System Preferences.app   / ��  ��  ��  ��  ��       �� e f g������   e ��������
�� .aevtoappnull  �   � ****�� 0 	dockprops  �� 0 dockhidestate  ��   f �� h���� i j��
�� .aevtoappnull  �   � **** h k     � k k   l l   m m   n n  ) o o  a����  ��  ��   i   j  �� ������ &�� $�� !�� ��������������
�� 
xppb
�� kfrmID  
�� .miscmvisnull���     ****
�� .sysodelanull��� ��� nmbr
�� 
prcs
�� 
cwin
�� 
chbx
�� .prcsclicnull��� ��� uiel
�� 
dpas
�� 
pALL�� 0 	dockprops  
�� 
dahd�� 0 dockhidestate  
�� .aevtquitnull��� ��� null�� �� *���0j UOkj O� *��/ *��/ 
*��/j UUUO� J*�, C*�,EE` O_ a ,E` O*a ,e  � *�, *a ,*a ,FUUY 	e*a ,FUUO�j  g ���� p
�� 
deff
�� ****scal p �� q r
�� 
dmsz q ?�       r �� s t
�� 
dsze s ?ն�`    t ���� u
�� 
dahd
�� boovtrue u ���� v
�� 
dani
�� boovfals v ���� w
�� 
dmag
�� boovfals w ���� x
�� 
dpse
�� ****bott x ������
�� 
pcls
�� 
dpao��  
�� boovtrue��  ascr  ��ޭ