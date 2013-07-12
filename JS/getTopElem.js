function getFirstParagraphOnScreen()
{
	var windowX = window.scrollX;
	var parCount = 0;
	var paragraphs = document.getElementsByTagName('p');
	for (var i = 0; i < paragraphs.length; i++)
	{
		if (paragraphs[i].offsetLeft >= windowX)
		{
			return i;
		}
	}
	return -1;
}
getFirstParagraphOnScreen();