#include "Projectile.h"

Projectile::Projectile()
{

}

Projectile::Projectile(GLfloat speed, vec3 *dir, Shape *object, GLfloat range, int iff)
{
	this->iff = iff;
	this->speed = speed;
	this->range = range;
	target = object;

	GLfloat *tempPos = object->getPosition();

	positionX = tempPos[0];
	positionY = tempPos[1];
	positionZ = tempPos[2];

	//printf("Projectile Origin: {%f, %f, %f}\n", tempPos[0], tempPos[1], tempPos[2]);

	vectorX = dir->x;
	vectorY = dir->y;
	vectorZ = dir->z;

	endPositionX = tempPos[0] + (range * vectorX);
	endPositionY = tempPos[1] + (range * vectorY);
	endPositionZ = tempPos[2] + (range * vectorZ);

/*
	GLfloat *curYAxis = this->target->getYAxis();

	GLfloat xInc = (dir->x - curYAxis[0]);
	GLfloat yInc = (dir->y - curYAxis[1]);
	GLfloat zInc = (dir->z - curYAxis[2]);

	this->target->translate(0.0, 0.0, 0.0); //translate to center
	this->target->rotate(xInc, 1, 0, 0);
	this->target->rotate(yInc, 0, 1, 0);
	this->target->rotate(zInc, 0, 0, 1);
	this->target->translate(positionX, positionY, positionZ);

	delete[] curYAxis;
*/


	delete[] tempPos;
}

void Projectile::update()
{
	/*
	if (this->speed == LASER_SPEED_SLOW) printf("laser speed = SLOW\n");
	else if (this->speed == LASER_SPEED_MEDIUM) printf("laser speed = MEDIUM\n");
	else if (this->speed == LASER_SPEED_FAST) printf("laser speed = FAST\n");
	*/

	GLfloat dX = (this->speed * vectorX);
	GLfloat dY = (this->speed * vectorY);
	GLfloat dZ = (this->speed * vectorZ);

	this->positionX += dX;
	this->positionY += dY;
	this->positionZ += dZ;

	target->translate(dX, dY, dZ);
	
	if (target->rgb[0] >= 1 && target->rgb[1] >= 1 && target->rgb[2] >= 1)
	{
		target->rgb[0] = 0.3;
		target->rgb[1] = 0.3;
		target->rgb[2] = 0;
	}
	else if (target->rgb[0] >= 1 && target->rgb[1] >= 1)
	{
		target->rgb[2] += 0.3;
	}
	else
	{
		target->rgb[0] += 0.3;
		target->rgb[1] += 0.3;
	}
	
	glDisable(GL_LIGHTING);
	target->draw(GL_QUADS);
	glEnable(GL_LIGHTING);
}

void Projectile::update(std::list<NPC*>* targetList, GLfloat playerPos[3], float *playerHealth)
{
	GLfloat dX = (this->speed * vectorX);
	GLfloat dY = (this->speed * vectorY);
	GLfloat dZ = (this->speed * vectorZ);

	this->positionX += dX;
	this->positionY += dY;
	this->positionZ += dZ;

	target->translate(dX, dY, dZ);
	
	if (target->rgb[0] >= 1 && target->rgb[1] >= 1 && target->rgb[2] >= 1)
	{
		target->rgb[0] = 0.3;
		target->rgb[1] = 0.3;
		target->rgb[2] = 0;
	}
	else if (target->rgb[0] >= 1 && target->rgb[1] >= 1)
	{
		target->rgb[2] += 0.3;
	}
	else
	{
		target->rgb[0] += 0.3;
		target->rgb[1] += 0.3;
	}
	
	glDisable(GL_LIGHTING);
	target->draw(GL_QUADS);
	glEnable(GL_LIGHTING);

	Vertex curPos = Vertex(this->positionX, this->positionY, this->positionZ);

	if (this->iff == 0) //iterate over NPC's in the world, test for hits
	{
		for (std::list<NPC*>::iterator iter = targetList->begin(); iter != targetList->end(); iter++)
		{
			GLfloat *targetPosition = (*iter)->getPosition();
			if (curPos.getDistance(targetPosition) < 2.0)
			{
				(*iter)->health-=.25; //decrement enemy health counter
				//printf("HIT REGISTERED! Enemy's health at %f\n", (*iter)->health);
			}
			delete[] targetPosition;
		}
	}
	else //test for hits on the PLAYER
	{
		Vertex playerPosition = Vertex(playerPos);
		GLfloat *projectilePosition = new GLfloat[3];
		projectilePosition[0] = this->positionX;
		projectilePosition[1] = this->positionY;
		projectilePosition[2] = this->positionZ;

		if (playerPosition.getDistance(projectilePosition) < 2.0)
		{
			*playerHealth-=.02;
			playerHit = 1;
			//printf("PLAYER HIT DETECTED!! Player's health at %f\n", *playerHealth);
		}
		else
		{
			//playerHit = 0;
		}

		delete[] projectilePosition;
	}
	
}

bool Projectile::outOfRange()
{
	if ((positionX > endPositionX) || (positionY > endPositionY) || (positionZ > endPositionZ))	
	{
		//printf("projectile out of range!\n");
		return true;
	}
	else
	{
		return false;
	}
}

Shape *Projectile::getShape()
{
	return this->target;
}

void Projectile::align(vec3 *v) // accepts a NORMALIZED direction vector and aligns the shape's Y-axis with that vector.
{

}

Projectile::~Projectile()
{
	//printf("Calling projectile destructor.\n");
	//delete target;
}
