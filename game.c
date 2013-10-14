//Rabbit Farm, by Benjamin Heath (benjamin.joel.heath@gmail.com
//Based on the public domain Chase by Shiru (shiru@mail.ru)

/*-----------------------------------------------------------------------------
Copyright (c) 2013, Benjamin Heath (benjamin.joel.heath@gmail.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  DAMAGE.
-----------------------------------------------------------------------------*/



//include the library

#include "neslib.h"



//include nametables for all the screens such as title or game over



//include nametables for levels



//music data is included as .s files, with includes and exports into music.s



//game uses 12:4 fixed point calculations for enemy movements
#define FP_BITS	4



//max size of the game map
#define MAP_WDT			16
#define MAP_WDT_BIT		4
#define MAP_HGT			13



//macro for calculating map offset from screen space, as
//the map size is smaller than screen to save some memory
#define MAP_ADR(x,y)	((((y)-2)<<MAP_WDT_BIT)|(x))



//size of a map tile
#define TILE_SIZE		16
#define TILE_SIZE_BIT	4



//movement directions, match to the gamepad buttons bits to
//simplify some things
#define DIR_NONE		0
#define DIR_LEFT		PAD_LEFT
#define DIR_RIGHT		PAD_RIGHT
#define DIR_UP			PAD_UP
#define DIR_DOWN		PAD_DOWN



//tile numbers for certain things in the game map
//i.e. which object corresponds to a character in the tileset
#define TILE_PLAYER		0x10
#define TILE_ENEMY1		0x11
#define TILE_ENEMY2		0x12
#define TILE_ENEMY3		0x13
#define TILE_WALL		0x40
#define TILE_EMPTY		0x44
#define TILE_ITEM		0x45



//number of levels in the game
#define LEVELS_ALL		5



//numbers for screens that are displayed by the same function as the
//level number
#define SCREEN_GAMEOVER	(LEVELS_ALL+0)
#define SCREEN_WELLDONE	(LEVELS_ALL+1)



//total number of moving characters on the screen
#define PLAYER_MAX	4



//sound effect numbers, it is easier to use meaningful defines than
//remember actual numbers of the effects
#define SFX_START		0
#define SFX_ITEM		1
#define SFX_RESPAWN1	2
#define SFX_RESPAWN2	3



//palettes data



//metasprites



//list of metasprites



//list of the levels, include pointer to the packed nametable of the level,
//and pointer to the associated palette



//preinitialized update list used during the gameplay



//a nametable string with the game stats, created in NES Screen Tool
//and copy/pasted here with Shift+C



//list of screens such as level number, game over, and well done
//contains pointers to the packed nametables, and pointers to the
//associated music data



//large 1-5 numbers nametable definitons, 2x3 tiles each
//numbers were drawn one next to the other in NES Screen Tool,
//then that part of nametable was copy/pasted here with Shift+C
//here they are orderded as
//   top row of 11 22 33 44 55
//middle row of 11 22 33 44 55
//bottom row of 11 22 33 44 55



//array for game map, contains walls, empty spaces, and items
static unsigned char map[MAP_WDT*MAP_HGT];



//put all the subsequent global vars into zeropage, to make code faster and shorter
#pragma bss-name (push,"ZEROPAGE")
#pragma data-name(push,"ZEROPAGE")



//set of general purpose global vars that are used everywhere in the program
//this makes code faster and shorter, although not very convinent and readable
static unsigned char i,j;
static unsigned char ptr,spr;
static unsigned char px,py;
static unsigned char wait;
static unsigned int i16;
static int iy,dy;



//this array is used to determine movement directions for enemies
static unsigned char dir[4];



//this array is used to convert nametable into game map, row by row
static unsigned char nameRow[32];



//number of moving characters on current level
static unsigned char player_all;



//character variables
static unsigned int  player_x    [PLAYER_MAX];
static unsigned int  player_y    [PLAYER_MAX];
static unsigned char player_dir  [PLAYER_MAX];
static int           player_cnt  [PLAYER_MAX];
static unsigned int  player_speed[PLAYER_MAX];
static unsigned char player_wait [PLAYER_MAX];



//number of items on current level, total and collected
static unsigned char items_count;
static unsigned char items_collected;



//game state variables
static unsigned char game_level;
static unsigned char game_lives;



//game state flags, they are 0 or 1
static unsigned char game_done;
static unsigned char game_paused;
static unsigned char game_clear;



//system vars used everywhere as well
static unsigned char frame_cnt;
static unsigned char bright;



//update list
static unsigned char update_list[7*3];



//delay the program for given number
//it is measured in 1/50s, so 50 is one second
void delay(unsigned char time)
{
	for(wait=0;wait<time;++wait) ppu_waitnmi();
}



//smoothly fade current bright to the given value
//in case when to=0 it also stops the music,
//turns the display off, reset vram update and scroll
void pal_fade_to(unsigned to)
{
	if(!to) music_stop();

	while(bright!=to)
	{
		delay(4);
		if(bright<to) ++bright; else --bright;
		pal_bright(bright);
	}

	if(!bright)
	{
		ppu_off();
		set_vram_update(0,0);
		scroll(0,0);
	}
}



//show title screen
void title_screen(void)
{
/*	scroll(-8,240);//title is aligned to the color attributes, so shift it a bit to the right
	unrle_vram(title_nam,0x2000);
	vram_adr(0x2800);//clear second nametable, as it is visible in the jumping effect
	vram_fill(0,1024);
	pal_bg(palTitle);
	pal_bright(4);
	ppu_on_bg();
	delay(20);//delay just to make it look better

	iy=240<<FP_BITS;
	dy=-8<<FP_BITS;
	frame_cnt=0;
	wait=160;
	bright=4;

	while(1)
	{
		ppu_waitnmi();
		scroll(-8,iy>>FP_BITS);

		if(pad_trigger(0)&PAD_START) break;

		iy+=dy;

		if(iy<0)
		{
			iy=0;
			dy=-dy>>1;
		}

		if(dy>(-8<<FP_BITS)) dy-=2;

		if(wait)
		{
			--wait;
		}
		else
		{
			pal_col(2,(frame_cnt&32)?0x0f:0x20);//blinking press start text
			++frame_cnt;
		}
	}

	scroll(-8,0);//if start is pressed, show the title at whole
	sfx_play(SFX_START,0);

	for(i=0;i<16;++i)//and blink the text faster
	{
		pal_col(2,i&1?0x0f:0x20);
		delay(4);
	}

	pal_fade_to(0);*/
}



//show level intro, game over, or well done screen
void show_screen(unsigned char num)
{
/*	scroll(-4,0); //all the screens are misaligneg horizontally by half of a tile

	if(num<LEVELS_ALL) spr=0; else spr=(num-LEVELS_ALL+1)<<1;//get offset in the screens list

	unrle_vram(screenList[spr],0x2000);

	if(!spr)//if it is the level screen, print large number
	{
		j=num<<1;
		i16=0x2194;//position of the number in the nametable

		for(i=0;i<3;i++)
		{
			vram_adr(i16);
			vram_put(largeNums[j]);
			vram_put(largeNums[j+1]);
			j+=10;
			i16+=32;
		}
	}

	i16=(num==SCREEN_GAMEOVER)?0x1525:0x1121;//two colors for flashing text in LSB and MSB
	frame_cnt=0;

	pal_col(2,i16&0xff);//this palette entry is used for flashing text
	pal_col(3,0x30);
	pal_col(6,0x30);
	ppu_on_bg();

	pal_fade_to(4);
	music_play(screenList[spr+1]);

	if(!spr)//if it is the level screen, just wait one second
	{
		delay(50);
	}
	else//otherwise wait for Start button and display flashing text
	{
		while(1)
		{
			ppu_waitnmi();
			pal_col(2,frame_cnt&2?i16&0xff:i16>>8);
			if(pad_trigger(0)&PAD_START) break;
			frame_cnt++;
		}
	}

	pal_fade_to(0);*/
}



//set up a move in the specified direction if there is no wall
void player_move(unsigned char id,unsigned char dir)
{
	px=player_x[id]>>(TILE_SIZE_BIT+FP_BITS);
	py=player_y[id]>>(TILE_SIZE_BIT+FP_BITS);

	switch(dir)
	{
	case DIR_LEFT:  --px; break;
	case DIR_RIGHT: ++px; break;
	case DIR_UP:    --py; break;
	case DIR_DOWN:  ++py; break;
	}

	if(map[MAP_ADR(px,py)]==TILE_WALL) return;

	player_cnt[id]=TILE_SIZE<<FP_BITS;
	player_dir[id]=dir;
}



//print a 1-3 digit decimal number into VRAM
void put_num(unsigned int adr,unsigned int num,unsigned char len)
{
	vram_adr(adr);

	if(len>2) vram_put(0x10+num/100);
	if(len>1) vram_put(0x10+num/10%10);
	vram_put(0x10+num%10);
}



//the main gameplay code
void game_loop(void)
{
/*	oam_clear();

	i=game_level<<1;
	unrle_vram(levelList[i],0x2000);				//unpack level nametable
	vram_write((unsigned char*)statsStr,0x2042,27); //add game stats string
	pal_bg(levelList[i+1]); 						//set up background palette
	pal_spr(palGameSpr); 							//set up sprites palette

	player_all=0;
	items_count=0;
	items_collected=0;

	//this loop reads the level nametable back from VRAM, row by row,
	//constructs game map, removes spawn points from the nametable,
	//and writes back to the VRAM

	i16=0x2080;
	ptr=0;
	wait=0;

	for(i=2;i<MAP_HGT+2;++i)
	{
		vram_read(nameRow,i16,32);
		vram_adr(i16);

		for(j=0;j<MAP_WDT<<1;j+=2)
		{
			spr=nameRow[j];

			switch(spr)
			{
			case TILE_PLAYER://player
			case TILE_ENEMY1://enemies
			case TILE_ENEMY2:
			case TILE_ENEMY3:
				player_dir  [player_all]=DIR_NONE;
				player_x    [player_all]=(j<<3)<<FP_BITS;
				player_y    [player_all]=(i<<4)<<FP_BITS;
				player_cnt  [player_all]=0;
				player_wait [player_all]=16+((spr-TILE_PLAYER)<<4);
				player_speed[player_all]=(spr==TILE_PLAYER)?2<<FP_BITS:10+((spr-TILE_ENEMY1)<<1);
				++player_all;
				wait+=16;
				spr=TILE_EMPTY;
				break;

			case TILE_ITEM:
				++items_count;
				break;
			}

			map[ptr++]=spr;

			vram_put(spr);
			vram_put(nameRow[j+1]);
		}

		i16+=64;
	}

	//setup update list

	memcpy(update_list,updateListData,sizeof(updateListData));
	set_vram_update(21/3,update_list);

	//put constant game stats numbers, that aren't updated during level

	put_num(0x2048,game_level+1,1);
	put_num(0x2053,items_count,3);
	put_num(0x205d,game_lives-1,1);

	//enable display

	ppu_on_all();

	game_done=FALSE;
	game_paused=FALSE;
	game_clear=FALSE;

	bright=0;
	frame_cnt=0;

	while(!game_done)
	{
		//construct OAM from object parameters

		spr=(player_all-1)<<4;

		for(i=0;i<player_all;++i)
		{
			py=player_y[i]>>FP_BITS;

			if(player_wait[i])
			{
				if(player_wait[i]>=16||player_wait[i]&2) py=240;
			}

			oam_meta_spr(player_x[i]>>FP_BITS,py,spr,sprListPlayer[i]);
			spr-=16;
		}

		//wait for next frame
		//it is here and not at beginning of the loop because you need
		//to update OAM for the very first frame, and you also need to do that
		//right after object parameters were changed, so either OAM update should
		//be in a function that called before the loop and at the end of the loop,
		//or wait for NMI should be placed there
		//otherwise you would have situation update-wait-display, i.e.
		//one frame delay between action and display of its result

		ppu_waitnmi();

		++frame_cnt;

		//slowly fade virtual brightness to needed value,
		//which is max for gameplay or half for pause

		if(!(frame_cnt&3))
		{
			if(!game_paused&&bright<4) ++bright;
			if( game_paused&&bright>2) --bright;
			pal_bright(bright);
		}

		//poll the gamepad in the trigger mode

		i=pad_trigger(0);

		//it start was released and then pressed, toggle pause mode

		if(i&PAD_START)
		{
			game_paused^=TRUE;
			music_pause(game_paused);
		}

		//don't process anything in pause mode, just display latest game state

		if(game_paused) continue;

		//CHR bank switching animation with different speed for background and sprites

		bank_bg((frame_cnt>>4)&1);
		bank_spr((frame_cnt>>3)&1);

		//a counter that does not allow objects to move while spawn animation plays

		if(wait)
		{
			--wait;

			if(!wait) music_play(music_game);//start the music when all the objects spawned
		}

		//check for level completion condition

		if(items_collected==items_count)
		{
			music_play(music_clear);
			game_done=TRUE;
			game_clear=TRUE;
		}

		//process all the objects
		//player and enemies are the same type of object in this game,
		//to make code simpler and shorter, but generally they need to be
		//different kind of objects

		for(i=0;i<player_all;++i)
		{
			//per-object spawn animation counter, it counts fron N to 16 to 0
			//needed because objects spawn in sequence, not all at once

			if(player_wait[i])
			{
				if(player_wait[i]==16) sfx_play(i?SFX_RESPAWN2:SFX_RESPAWN1,i);
				--player_wait[i];
				continue;
			}

			if(wait) continue; //don't process object movements if spawn animation is running

			//check collision of an enemy object with player object
			//NOT logic is used here, check http://gendev.spritesmind.net/page-collide.html

			if(i)
			{
				if(!((player_x[i]+(4 <<FP_BITS))>=(player_x[0]+(12<<FP_BITS))||
				     (player_x[i]+(12<<FP_BITS))< (player_x[0]+(4 <<FP_BITS))||
					 (player_y[i]+(4 <<FP_BITS))>=(player_y[0]+(12<<FP_BITS))||
					 (player_y[i]+(12<<FP_BITS))< (player_y[0]+(4 <<FP_BITS))))
				{
					//if an enemy touch the player, quit the game loop

					if(!game_clear)
					{
						music_play(music_lose);
						game_done=TRUE;
						break;
					}
				}
			}

			//if movement counter is not zero, process the movement

			if(player_cnt[i])
			{
				switch(player_dir[i])
				{
				case DIR_RIGHT: player_x[i]+=player_speed[i]; break;
				case DIR_LEFT:  player_x[i]-=player_speed[i]; break;
				case DIR_DOWN:  player_y[i]+=player_speed[i]; break;
				case DIR_UP:    player_y[i]-=player_speed[i]; break;
				}

				player_cnt[i]-=player_speed[i];

				//if move from one tile to another is over, realign the object to tile grid
				//it is needed because when it moves with non-integer speed, it could
				//overrun the destination tile a little bit, and thus can't take a turn properly

				if(player_cnt[i]<=0)
				{
					if(player_cnt[i]<0) //overrun
					{
						player_cnt[i]=0;

						//0xff is a coordinate mask that leaves only integer tile offeset
						//it is 8:4:4 here, where 8 is integer tile coordinate,
						//first 4 is offset in the tile, which is 16 pixels wide,
						//and second 4 is fixed point resolution

						player_x[i]=(player_x[i]&0xff00)+(player_dir[i]==DIR_LEFT?0x100:0);
						player_y[i]=(player_y[i]&0xff00)+(player_dir[i]==DIR_UP  ?0x100:0);
					}

					//it is is the player object, check if there is an item in the new tile
					if(!i)
					{
						i16=MAP_ADR((player_x[i]>>(TILE_SIZE_BIT+FP_BITS)),
						            (player_y[i]>>(TILE_SIZE_BIT+FP_BITS)));

						if(map[i16]==TILE_ITEM)
						{
							map[i16]=TILE_EMPTY; //mark as collected in the game map

							sfx_play(SFX_ITEM,2);
							++items_collected;

							//get address of the tile in the nametable

							i16=0x2080+(((player_y[i]>>(TILE_SIZE_BIT+FP_BITS))-2)<<6)|
							            ((player_x[i]>>(TILE_SIZE_BIT+FP_BITS))<<1);

							//replace it with empty tile through the update list

							update_list[0]=i16>>8;
							update_list[1]=i16&255;
							update_list[3]=update_list[0];
							update_list[4]=update_list[1]+1;
							i16+=32;
							update_list[6]=i16>>8;
							update_list[7]=i16&255;
							update_list[9]=update_list[6];
							update_list[10]=update_list[7]+1;

							//update number of collected items in the game stats

							update_list[14]=0x10+items_collected/100;
							update_list[17]=0x10+items_collected/10%10;
							update_list[20]=0x10+items_collected%10;
						}
					}
				}
			}

			if(!player_cnt[i]) //movement to the next tile is done, set up new movement
			{
				if(!i) //this is the player, process controls
				{
					//get gamepad state, it was previously polled with pad_trigger

					j=pad_state(0);

					//this is a tricky part to make controls more predictable
					//when you press two directions at once, sliding by a wall
					//to take turn into a passage on the side
					//this piece of code gives current direction lower priority
					//through testing it first
					//bits in player_dir var are matching to the buttons bits

					if(j&player_dir[0])
					{
						j&=~player_dir[0]; //remove the direction from further check
						player_move(i,player_dir[0]); //change the direction
					}

					//now continue control processing as usual

					if(j&PAD_LEFT)  player_move(i,DIR_LEFT);
					if(j&PAD_RIGHT) player_move(i,DIR_RIGHT);
					if(j&PAD_UP)    player_move(i,DIR_UP);
					if(j&PAD_DOWN)  player_move(i,DIR_DOWN);
				}
				else //this is an enemy, run AI
				{
					//the AI is very simple
					//first we create list of all directions that are possible to take
					//excluding the direction that is opposite to previous one

					i16=MAP_ADR((player_x[i]>>8),(player_y[i]>>8));
					ptr=player_dir[i];
					j=0;

					if(ptr!=DIR_RIGHT&&map[i16-1]!=TILE_WALL) dir[j++]=DIR_LEFT;
					if(ptr!=DIR_LEFT &&map[i16+1]!=TILE_WALL) dir[j++]=DIR_RIGHT;
					if(ptr!=DIR_DOWN &&map[i16-MAP_WDT]!=TILE_WALL) dir[j++]=DIR_UP;
					if(ptr!=DIR_UP   &&map[i16+MAP_WDT]!=TILE_WALL) dir[j++]=DIR_DOWN;

					//randomly select a possible direction

					player_move(i,dir[rand8()%j]);

					//if there was more than one possible direction,
					//i.e. it is a branch and not a corridor,
					//attempt to move towards the player

					if(j>1)
					{
						if(ptr!=DIR_DOWN &&player_y[0]<player_y[i]) player_move(i,DIR_UP);
						if(ptr!=DIR_UP   &&player_y[0]>player_y[i]) player_move(i,DIR_DOWN);
						if(ptr!=DIR_RIGHT&&player_x[0]<player_x[i]) player_move(i,DIR_LEFT);
						if(ptr!=DIR_LEFT &&player_x[0]>player_x[i]) player_move(i,DIR_RIGHT);
					}
				}
			}
		}
	}

	delay(100);
	pal_fade_to(0);*/
}



//this is where the program starts
void main(void)
{
	while(1)//infinite loop, title-gameplay
	{
		title_screen();

		game_level=0;
		game_lives=4;

		while(game_lives&&game_level<LEVELS_ALL)//loop for gameplay
		{
			show_screen(game_level);
			game_loop();

			if(game_clear) ++game_level; else --game_lives;
		}

		show_screen(!game_lives?SCREEN_GAMEOVER:SCREEN_WELLDONE);//show game results
	}
}
